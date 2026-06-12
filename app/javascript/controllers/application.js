import { Application } from "@hotwired/stimulus";
import NewBulkImportController from "./new_bulk_import_controller";
import UserSearchController from "./user_search_controller";

const application = Application.start();

application.debug = false;
window.Stimulus = application;

application.register("new-bulk-import", NewBulkImportController);
application.register("user-search", UserSearchController);

export { application };
