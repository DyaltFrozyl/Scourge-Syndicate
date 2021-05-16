function init()
  object.setInteractive(true)
  self.chatIndex = 0
end

function onInteraction(args)
  local chatOptions = config.getParameter("chatOptions", {})
  object.say(chatOptions[(self.chatIndex % #chatOptions) + 1])
  self.chatIndex = self.chatIndex + 1
  animator.playSound("chatter")
end
