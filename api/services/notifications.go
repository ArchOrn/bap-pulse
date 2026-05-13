package services

import (
	"context"
	"encoding/json"
	"log"

	"firebase.google.com/go/v4/messaging"

	"bap-pulse/db"
)

// Notifier persists in-app notifications and dispatches the matching push to
// every device registered for the recipient. The DB row is the source of
// truth for the in-app notification center; FCM delivery is best-effort.
type Notifier struct {
	q   *db.Queries
	msg *messaging.Client
}

// NewNotifier returns a Notifier. msg may be nil — in that case the FCM hop is
// skipped (useful for tests and for environments without Firebase credentials).
func NewNotifier(q *db.Queries, msg *messaging.Client) *Notifier {
	return &Notifier{q: q, msg: msg}
}

// Send creates a notification row for userID and pushes to every FCM token
// registered for that user. data is serialized as the JSONB payload and passed
// through to FCM as a string-keyed map (FCM only accepts string values).
//
// Failures from FCM never propagate: the notification has already been
// persisted, and the next time the app opens it will pick it up from the
// notification center. Tokens reported as unregistered or invalid are purged.
func (n *Notifier) Send(
	ctx context.Context,
	userID string,
	notifType db.NotificationType,
	title, body string,
	data map[string]string,
) error {
	if data == nil {
		data = map[string]string{}
	}
	dataJSON, err := json.Marshal(data)
	if err != nil {
		return err
	}

	if _, err := n.q.CreateNotification(ctx, db.CreateNotificationParams{
		UserID: userID,
		Type:   notifType,
		Title:  title,
		Body:   body,
		Data:   dataJSON,
	}); err != nil {
		return err
	}

	if n.msg == nil {
		return nil
	}

	tokens, err := n.q.ListFcmTokensForUser(ctx, userID)
	if err != nil {
		log.Printf("notifier: list tokens: %v", err)
		return nil
	}
	if len(tokens) == 0 {
		return nil
	}

	// FCM data payloads must be strings. We always include the type so the
	// client can branch deep-link routing without re-parsing the title.
	payload := map[string]string{"type": string(notifType)}
	for k, v := range data {
		payload[k] = v
	}

	tokenValues := make([]string, len(tokens))
	for i, t := range tokens {
		tokenValues[i] = t.Token
	}

	resp, err := n.msg.SendEachForMulticast(ctx, &messaging.MulticastMessage{
		Tokens: tokenValues,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: payload,
	})
	if err != nil {
		log.Printf("notifier: SendEachForMulticast: %v", err)
		return nil
	}

	// Collect dead tokens so they can be purged in one shot.
	var dead []string
	for i, r := range resp.Responses {
		if r.Success {
			continue
		}
		if messaging.IsUnregistered(r.Error) || messaging.IsInvalidArgument(r.Error) {
			dead = append(dead, tokenValues[i])
		}
	}
	if len(dead) > 0 {
		if err := n.q.DeleteFcmTokensByValue(ctx, dead); err != nil {
			log.Printf("notifier: purge dead tokens: %v", err)
		}
	}
	return nil
}
