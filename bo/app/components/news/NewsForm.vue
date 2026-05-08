<script setup lang="ts">
import { MdEditor, type ToolbarNames } from 'md-editor-v3'
import 'md-editor-v3/lib/style.css'
import EmojiPicker from 'vue3-emoji-picker'
import 'vue3-emoji-picker/css'
import { parseMarkdown } from '~/utils/markdown'

interface Props {
  modelEmoji: string
  modelTitle: string
  modelBody: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelEmoji': [value: string]
  'update:modelTitle': [value: string]
  'update:modelBody': [value: string]
}>()

const emoji = computed({
  get: () => props.modelEmoji,
  set: v => emit('update:modelEmoji', v)
})
const title = computed({
  get: () => props.modelTitle,
  set: v => emit('update:modelTitle', v)
})
const body = computed({
  get: () => props.modelBody,
  set: v => emit('update:modelBody', v)
})

// Toolbar limited to what the app's renderer supports + universal helpers.
// 'preview' toggles the editor's own side-by-side preview (it shows the full
// Markdown, while our "App preview" panel below shows what the app will render).
const toolbars: ToolbarNames[] = [
  'bold', 'italic', '-',
  'preview', '-',
  'revoke', 'next'
]

const titleSegments = computed(() => parseMarkdown(props.modelTitle))
const bodyParagraphs = computed(() =>
  (props.modelBody ?? '').split(/\n\n+/).map(p => parseMarkdown(p))
)

// Emoji picker. Opens a popover anchored on the trigger button. Selecting an
// emoji sets the v-model and auto-closes the popover.
const showPicker = ref(false)

interface EmojiPick { i: string }
const onPickEmoji = (e: EmojiPick) => {
  emoji.value = e.i
  showPicker.value = false
}
</script>

<template>
  <div class="space-y-5">
    <div class="grid grid-cols-[auto_1fr] gap-4">
      <UFormField label="Emoji">
        <UPopover
          v-model:open="showPicker"
          :content="{ side: 'bottom', align: 'start' }"
        >
          <button
            type="button"
            class="h-12 min-w-[64px] px-3 rounded-md border border-default bg-elevated hover:bg-accented text-2xl flex items-center justify-center transition-colors"
            :aria-label="emoji ? 'Changer l\'emoji' : 'Choisir un emoji'"
          >
            <span v-if="emoji">{{ emoji }}</span>
            <UIcon
              v-else
              name="i-lucide-smile-plus"
              class="size-5 text-muted"
            />
          </button>

          <template #content>
            <EmojiPicker
              :native="true"
              theme="dark"
              :hide-search="false"
              :disable-skin-tones="true"
              @select="onPickEmoji"
            />
          </template>
        </UPopover>
      </UFormField>

      <UFormField
        label="Titre"
        help="Markdown : **gras** (couleur d'accent), *italique*."
      >
        <UInput
          v-model="title"
          class="w-full"
        />
      </UFormField>
    </div>

    <UFormField
      label="Corps (optionnel)"
      help="Affiché sur la page de détail. Markdown : **gras**, *italique*, listes, retours à la ligne."
    >
      <MdEditor
        v-model="body"
        theme="dark"
        language="en-US"
        preview-theme="github"
        :toolbars="toolbars"
        :preview="false"
        :tab-width="2"
        style="height: 320px;"
      />
    </UFormField>

    <div>
      <p class="text-sm font-medium mb-2">
        Aperçu app
      </p>
      <div class="rounded-xl border border-default p-4 bg-elevated flex gap-3">
        <span
          v-if="emoji"
          class="text-2xl leading-none shrink-0"
        >{{ emoji }}</span>
        <span
          v-else
          class="text-2xl leading-none shrink-0 opacity-30"
        >·</span>

        <div class="flex-1 min-w-0">
          <p class="text-base">
            <template
              v-for="(seg, i) in titleSegments"
              :key="i"
            >
              <span
                v-if="seg.style === 'accent'"
                class="font-semibold text-primary"
              >{{ seg.text }}</span>
              <em
                v-else-if="seg.style === 'italic'"
                class="text-default"
              >{{ seg.text }}</em>
              <span v-else>{{ seg.text }}</span>
            </template>
          </p>

          <div
            v-if="bodyParagraphs.some(p => p.length > 0)"
            class="mt-3 space-y-2 text-sm text-muted"
          >
            <p
              v-for="(p, i) in bodyParagraphs"
              :key="i"
            >
              <template
                v-for="(seg, j) in p"
                :key="j"
              >
                <span
                  v-if="seg.style === 'accent'"
                  class="font-semibold text-primary"
                >{{ seg.text }}</span>
                <em
                  v-else-if="seg.style === 'italic'"
                >{{ seg.text }}</em>
                <span v-else>{{ seg.text }}</span>
              </template>
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
