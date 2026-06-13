browser.action.onClicked.addListener((tab) => {
  browser.scripting.executeScript({
    target: { tabId: tab.id },
    files: ["content.js"]
  });
});

browser.runtime.onMessage.addListener((message) => {
  if (message.text) {
    browser.runtime.sendNativeMessage("", { text: message.text });
  }
});
