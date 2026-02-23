<script setup>
defineProps({
  active: { type: Boolean, default: false },
  width:  { type: Number, default: 380 },
  height: { type: Number, default: 280 },
})

// Executive update thread during the incident
const CEO_MESSAGES = [
  { user: 'CEO_BigBoss', text: 'What is the current impact?', time: '9:45:30 AM', type: 'incoming' },
  { user: 'CEO_BigBoss', text: 'Support reports failed checkouts.', time: '9:45:35 AM', type: 'incoming' },
  { user: 'CEO_BigBoss', text: 'Please provide recovery ETA.', time: '9:46:15 AM', type: 'incoming' },
  { user: 'Me', text: 'Investigating now. Will update in 2 minutes.', time: '9:46:20 AM', type: 'outgoing' },
  { user: 'CEO_BigBoss', text: 'Understood. Keep me posted.', time: '9:47:45 AM', type: 'incoming' },
  { user: 'CEO_BigBoss', text: 'Comms team is preparing a status note.', time: '9:48:12 AM', type: 'incoming' },
  { user: 'Me', text: 'Issue isolated to a bad commit. Reverting now.', time: '9:49:30 AM', type: 'outgoing' },
  { user: 'CEO_BigBoss', text: 'Thanks. Confirm once fully stable.', time: '9:51:20 AM', type: 'incoming' },
]
</script>

<template>
  <div class="ceo-chat-window" :style="{ width: width + 'px', height: height + 'px' }">

    <!-- Title bar -->
    <div class="win-titlebar" :class="{ inactive: !active }">
      <span class="win-icon">👔</span>
      <span class="win-title">Instant Message - CEO_BigBoss</span>
      <div class="win-controls">
        <span class="win-ctrl">_</span>
        <span class="win-ctrl">□</span>
        <span class="win-ctrl win-ctrl-close">✕</span>
      </div>
    </div>

    <!-- Chat header -->
    <div class="chat-header">
      <div class="chat-user-info">
        <span class="chat-avatar">CEO</span>
        <div class="chat-user-details">
          <span class="chat-username">CEO_BigBoss</span>
          <span class="chat-status">Online - awaiting incident updates</span>
        </div>
      </div>
    </div>

    <!-- Chat messages -->
    <div class="chat-messages">
      <div
        v-for="(msg, i) in CEO_MESSAGES"
        :key="i"
        class="chat-message"
        :class="msg.type"
      >
        <div class="chat-msg-header">
          <span class="chat-msg-user">{{ msg.user }}</span>
          <span class="chat-msg-time">{{ msg.time }}</span>
        </div>
        <div class="chat-msg-text">{{ msg.text }}</div>
      </div>
    </div>

    <!-- Chat input -->
    <div class="chat-input-area">
      <input type="text" class="chat-input" placeholder="Type a message..." readonly />
      <button class="chat-send-btn">Send</button>
    </div>

  </div>
</template>

<style scoped>
/* ── Window chrome ──────────────────────────────────────────── */
.ceo-chat-window {
  display: flex;
  flex-direction: column;
  border: 2px solid;
  border-color: #ffffff #808080 #808080 #ffffff;
  outline: 1px solid #000;
  background: #c0c0c0;
  overflow: hidden;
  flex-shrink: 0;
}

.win-titlebar {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 22px;
  padding: 0 2px 0 4px;
  background: linear-gradient(90deg, #800000 0%, #cc0000 100%);
  color: #fff;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 11px;
  flex-shrink: 0;
  user-select: none;
}

.win-titlebar.inactive {
  background: #808080;
  color: #d4d0c8;
}

.win-icon { font-size: 10px; flex-shrink: 0; }
.win-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.win-controls { display: flex; gap: 2px; flex-shrink: 0; }

.win-ctrl {
  width: 16px;
  height: 14px;
  background: #c0c0c0;
  color: #000;
  border: 1px solid;
  border-color: #fff #808080 #808080 #fff;
  font-size: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: default;
}

.win-ctrl-close { font-size: 7px; }

/* ── Chat header ────────────────────────────────────────────── */
.chat-header {
  background: #ffe0e0;
  border-bottom: 1px solid #808080;
  padding: 6px 8px;
  flex-shrink: 0;
}

.chat-user-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.chat-avatar {
  font-size: 16px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fff;
  border: 1px solid #808080;
}

.chat-user-details {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.chat-username {
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 13px;
  font-weight: bold;
  color: #800000;
}

.chat-status {
  font-family: 'Tahoma', sans-serif;
  font-size: 10px;
  color: #666;
}

/* ── Chat messages ──────────────────────────────────────────── */
.chat-messages {
  flex: 1;
  background: #fff;
  padding: 8px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-family: 'Tahoma', sans-serif;
}

.chat-message {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.chat-message.incoming {
  align-items: flex-start;
}

.chat-message.outgoing {
  align-items: flex-end;
}

.chat-msg-header {
  display: flex;
  gap: 6px;
  align-items: center;
}

.chat-message.outgoing .chat-msg-header {
  flex-direction: row-reverse;
}

.chat-msg-user {
  font-size: 11px;
  font-weight: bold;
  color: #800000;
}

.chat-message.outgoing .chat-msg-user {
  color: #004a7f;
}

.chat-msg-time {
  font-size: 9px;
  color: #666;
}

.chat-msg-text {
  background: #ffe8e8;
  border: 1px solid #cc9999;
  padding: 4px 7px;
  max-width: 230px;
  word-wrap: break-word;
  font-size: 12px;
  line-height: 1.3;
  color: #000;
  border-radius: 2px;
}

.chat-message.outgoing .chat-msg-text {
  background: #fff2cc;
  border-color: #d6b656;
}

/* ── Chat input ─────────────────────────────────────────────── */
.chat-input-area {
  display: flex;
  border-top: 1px solid #808080;
  background: #c0c0c0;
  padding: 4px;
  gap: 4px;
  flex-shrink: 0;
}

.chat-input {
  flex: 1;
  border: 2px solid;
  border-color: #808080 #fff #fff #808080;
  padding: 2px 4px;
  font-family: 'Tahoma', sans-serif;
  font-size: 10px;
  background: #fff;
}

.chat-send-btn {
  border: 2px solid;
  border-color: #fff #808080 #808080 #fff;
  background: #c0c0c0;
  padding: 2px 8px;
  font-family: 'Silkscreen', 'Tahoma', sans-serif;
  font-size: 9px;
  color: #000;
  cursor: default;
}

.chat-send-btn:active {
  border-color: #808080 #fff #fff #808080;
}
</style>
