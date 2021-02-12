public with sharing class ContentDocumentLinkTriggerHandler {

    public void handleAfterInsert( List<ContentDocumentLink> newList, Map<ID, ContentDocumentLink> newMap ) {

        System.debug( 'ContentDocumentLinkTriggerHandler.afterInsert' );

        // To avoid the Flow needing to make an extra query to learn the ContentVersionId
        // of the document that was shared to the record, we can perform that query here.
        // Due to a silly implementation restriction with ContentDocumentLink object, queries
        // require a filter on ContentDocumentId or LinkedEntityId field.
        // Despite having the ID of the ContentDocumentLink records we want, if we
        // do a query we have to filter by one of the other fields.
        // We can iterate the list of CDLs that we have and filter by that.

        Set<ID> contentDocumentIds = new Set<ID>();
        Set<ID> linkedEntityIds = new Set<ID>();
        for ( ContentDocumentLink cdl : newList ) {
            String strId = Id.valueOf(cdl.LinkedEntityId);
            if(strId.StartsWith('a0g')) { //only if it's related to an invoice!
            contentDocumentIds.add( cdl.ContentDocumentId );
            linkedEntityIds.add( cdl.LinkedEntityId );
            }
        }

        
        if(LinkedEntityIds.size()>0) { //only continue if it started with an Invoice file
        
            // Re-query to get the Title from the ContentDocument
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>([
            SELECT
                Id,
                LinkedEntityId,
                Visibility,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.Title
            FROM
                ContentDocumentLink
            WHERE
                // filtering by id "should" be the only filter needed...
                Id IN :newList
                AND
                // but due to implementation restriction, we need another filter...
                ContentDocumentId IN :contentDocumentIds
        ]);
        
        String docType = ''; //we'll use this as our comparison string

        for (ContentDocumentLink cdl : cdls){
            if(cdl.ContentDocument.Title.containsIgnoreCase('usage ') || cdl.ContentDocument.Title.containsIgnoreCase('itemised ') || cdl.ContentDocument.Title.containsIgnoreCase('log ')) { //is it an itemised invoice?
                cdl.Visibility = 'AllUsers';
                docType = 'Itemised';
            } else if(cdl.ContentDocument.Title.startsWithIgnoreCase('Invoice ')) { //is it an invoice?
                cdl.Visibility = 'AllUsers';
                docType = 'Invoice';
            }  
        }
        //update the new files
        update cdls;

        //find related document links that look like Invoices
        if(docType=='Invoice'){
        List<ContentDocumentLink> oldLinks = new List<ContentDocumentLink>([
            SELECT
                Id,
                LinkedEntityId,
                Visibility,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.Title
            FROM
                ContentDocumentLink
            WHERE
                Id NOT IN :cdls
                AND
                LinkedEntityId IN :linkedEntityIds
                AND 
                Visibility = 'AllUsers'
                AND
                (ContentDocument.Title LIKE 'Invoice %' AND (NOT ContentDocument.Title LIKE '%itemised%') AND (NOT ContentDocument.Title LIKE '%usage%') AND (NOT ContentDocument.Title LIKE '%log%'))
                ]);
        
        //update related document links to hide what we've found
        for (ContentDocumentLink link : oldLinks) {
            link.Visibility = 'InternalUsers';
        }
        update oldLinks;

        List<Invoice__c> invoices = new List<Invoice__c>([
            SELECT Id, Lastest_Invoice_Id__c FROM Invoice__c WHERE Id IN :linkedEntityIds
        ]);

        for(Invoice__c invoice : invoices) {
            for(ContentDocumentLink cdl : cdls) {
                if(invoice.Id == cdl.LinkedEntityId) {
                    invoice.Lastest_Invoice_Id__c = cdl.ContentDocumentId;
                }
            }
        }
        update invoices;
        }
        else if(docType=='Itemised'){
            List<ContentDocumentLink> oldLinks = new List<ContentDocumentLink>([
                SELECT
                    Id,
                    LinkedEntityId,
                    Visibility,
                    ContentDocumentId,
                    ContentDocument.LatestPublishedVersionId,
                    ContentDocument.Title
                FROM
                    ContentDocumentLink
                WHERE
                    Id NOT IN :cdls
                    AND
                    LinkedEntityId IN :linkedEntityIds
                    AND 
                    Visibility = 'AllUsers'
                    AND
                    (ContentDocument.Title LIKE '%itemised%' OR ContentDocument.Title LIKE '%usage%' OR ContentDocument.Title LIKE '%log%')
                    ]);
            
            //update related document links to hide what we've found
            for (ContentDocumentLink link : oldLinks) {
                link.Visibility = 'InternalUsers';
            }
            update oldLinks;
        }
    }
        

        /* original

        // Re-query to get the ContentVersionId from the ContentDocument
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>([
            SELECT
                Id,
                LinkedEntityId,
                Visibility,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.Title
            FROM
                ContentDocumentLink
            WHERE
                // filtering by id "should" be the only filter needed...
                Id IN :newList
                AND
                // but due to implementation restriction, we need another filter...
                ContentDocumentId IN :contentDocumentIds
        ]);

        Set<String> docTitles = new Set<String>();
        for(ContentDocumentLink cdl : cdls) {
            docTitles.add(cdl.ContentDocument.Title);
            cdl.Visibility = 'AllUsers';
        }

        //get related contentdocuments
        List<ContentDocument> relDocs = new List<ContentDocument>([
            Select
                Id,
                Title,
                LatestPublishedVersionId
            FROM
                ContentDocument
            WHERE
                Id NOT IN :contentDocumentIds
                AND
                Title IN :docTitles
        ]);

        Set<ID> relcontentDocumentIds = new Set<ID>();
        for ( ContentDocument cd : relDocs ) {
            relcontentDocumentIds.add( cd.Id );
        }

        //get related contentdocumentlinks that need closing
        List<ContentDocumentLink> relLinks = new List<ContentDocumentLink>([
            SELECT 
                Id,
                LinkedEntityId,
                Visibility,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.Title
            FROM
                ContentDocumentLink
            WHERE
                ContentDocumentId IN :relcontentDocumentIds

        ]);

        for ( ContentDocumentLink cdl : cdls ) {

            // Launch flow from apex
            // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/flow_interview_class.htm

            Map<String, Object> inputs = new Map<String, Object>{
                'varContentDocumentLinkId' => cdl.Id,
                'varRecordId' => cdl.LinkedEntityId,
                'varContentDocumentId' => cdl.ContentDocumentId,
                'varContentVersionId' => cdl.ContentDocument.LatestPublishedVersionId,
                'varFileName' => cdl.ContentDocument.Title
            };

            // For discussion about invoking flow in a loop and governor limits,
            // see this tweet thread: https://twitter.com/Nads_P07/status/1140341833689518080
            Flow.Interview myFlow = Flow.Interview.createInterview( 'Handle_File_Shared_To_Record_Flow', inputs );
            myFlow.start();

        }*/

    }

}
