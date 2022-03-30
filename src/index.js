import { Elm } from "./Main.elm";

Elm.Main.init({
  node: document.getElementById("main"),
  flags: process.env.CLIENT_ID,
});
