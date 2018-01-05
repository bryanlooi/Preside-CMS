/**
 * Handler that provides default actions for building links to admin object
 * screens.
 *
 */
component {

	property name="dataManagerService" inject="dataManagerService";

	private string function buildListingLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.object"
			, queryString = "id=#objectName#"
		);
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var objectName  = args.objectName ?: "";
		var recordId    = args.recordId   ?: "";
		var queryString = "object=#objectName#&id=#recordId#";

		if ( ( args.language ?: "" ).len() ) {
			queryString &= "&language=#args.language#";
		}

		if ( dataManagerService.isOperationAllowed( objectName, "read" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.viewRecord"
				, queryString = queryString
			);
		}
		return "";
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "add" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.addRecord"
				, queryString = "object=#objectName#"
			);
		}

		return "";
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId   ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "edit" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.editRecord"
				, queryString = "object=#objectName#&id=#recordId#"
			);
		}

		return "";
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId   ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "delete" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.deleteRecordAction"
				, queryString = "object=#objectName#&id=#recordId#"
			);
		}

		return "";
	}

	private string function buildTranslateRecordLink( event, rc, prc, args={} ) {
		var objectName  = args.objectName ?: "";
		var recordId    = args.recordId   ?: "";
		var language    = args.language   ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "edit" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.translateRecord"
				, queryString = "object=#objectName#&id=#recordId#&language=#language#"
			);
		}
		return "";
	}

	private string function buildSortRecordsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isSortable( objectName ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.sortRecords"
				, queryString = "object=#objectName#"
			);
		}

		return "";
	}

	private string function buildManagePermsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.managePerms"
			, queryString = "object=#objectName#"
		);
	}

	private string function buildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var qs         = "id=#objectName#";
		var additionalArgs = [ "useMultiActions", "gridFields", "isMultilingual", "draftsEnabled" ];

		for( var arg in additionalArgs ) {
			if ( args.keyExists( arg ) ) {
				qs &= "&#arg#=#args[ arg ]#";
			}
		}

		return event.buildAdminLink(
			  linkto      = "datamanager.getObjectRecordsForAjaxDataTables"
			, queryString = qs
		);
	}

	private string function buildMultiRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.multiRecordAction"
			, queryString = "object=#objectName#"
		);
	}

	private string function buildExportDataActionLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo = "datamanager.exportDataAction" );
	}

	private string function buildDataExportConfigModalLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkTo      = "datamanager.dataExportConfigModal"
			, queryString = "object=#objectName#"
		);
	}

}