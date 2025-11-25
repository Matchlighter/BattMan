
// import 'semantic-ui-css/semantic.min.css';

import "@hotwired/turbo-rails";

document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})

import LocalTime from "local-time"
LocalTime.start()
