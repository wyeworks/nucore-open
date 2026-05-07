import { Application } from "@hotwired/stimulus";
import NewBulkImportController from "./new_bulk_import_controller";
import ProductNotification from "./product_notification_controller";

const application = Application.start();

application.debug = false;
window.Stimulus = application;

application.register("new-bulk-import", NewBulkImportController);
application.register("product-notification", ProductNotification);

export { application };
