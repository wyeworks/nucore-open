import "@hotwired/turbo-rails";

import './app';
import './utils';
import "./controllers";

// TODO: Enabling this improves perceived page navigation speed but requires
// refactoring js initialization we have on most pages which is done on the
// application bundle on document ready.
Turbo.session.drive = false;
