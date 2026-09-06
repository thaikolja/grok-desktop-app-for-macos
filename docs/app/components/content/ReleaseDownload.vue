<script setup lang="ts">
const config = useRuntimeConfig()

const version = computed(() => String(config.public.appVersion || '1.0.0'))
const repo = computed(() => String(config.public.githubRepo || 'thaikolja/grok-desktop-app-for-macos'))
const tag = computed(() => `v${version.value}`)
const dmgName = computed(() => `Grok-Desktop-${version.value}-universal.dmg`)
const zipName = computed(() => `Grok-Desktop-${version.value}-universal.zip`)
const dmgUrl = computed(() => `https://github.com/${repo.value}/releases/download/${tag.value}/${dmgName.value}`)
const zipUrl = computed(() => `https://github.com/${repo.value}/releases/download/${tag.value}/${zipName.value}`)
const releasesUrl = computed(() => `https://github.com/${repo.value}/releases`)
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex flex-wrap gap-3">
      <UButton
        :to="dmgUrl"
        color="neutral"
        size="lg"
        target="_blank"
        trailing-icon="i-lucide-download"
      >
        Download {{ dmgName }}
      </UButton>
      <UButton
        :to="zipUrl"
        color="neutral"
        variant="outline"
        size="lg"
        target="_blank"
      >
        {{ zipName }}
      </UButton>
    </div>
    <p class="text-muted text-sm">
      One file for Apple Silicon and Intel. Built by GitHub Actions.
      <UButton :to="releasesUrl" variant="link" color="neutral" size="sm" target="_blank">
        All releases
      </UButton>
    </p>
  </div>
</template>
