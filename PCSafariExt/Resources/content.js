 (async () => {
   if (document.getElementById("pastecard-saving")) return;

   const text = window.getSelection()?.toString().trim() || "";
   const payload = text.length > 0 ? text : window.location.href;

   const div = document.createElement("div");
   div.id = "pastecard-saving";
   div.textContent = "Saving to Pastecard…";
   Object.assign(div.style, {
     position:       "fixed",
     top:            "0",
     left:           "0",
     right:          "0",
     height:         "44px",
     display:        "flex",
     alignItems:     "center",
     justifyContent: "center",
     background:     "#fafafa",
     borderTop:      "4px solid #004080",
     fontSize:       "18px",
     fontFamily:     "-apple-system, sans-serif",
     zIndex:         "2147483647",
     boxSizing:      "border-box",
   });
   document.body.appendChild(div);

   browser.runtime.sendMessage({ text: payload });

   await new Promise(r => setTimeout(r, 750));
   div.remove();
 })();
