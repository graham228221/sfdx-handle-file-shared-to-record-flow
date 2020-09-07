@IsTest
private class ContentDocumentLinkTriggerHandlerTest {

    @IsTest
    static void test_share_file_to_record() {

        // You may need to modify this
        // test to be able to insert an account
        // that meets your org's validation requirements.
        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'This is a test',
            AccountId = acct.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );

        insert opp;

        Invoice__c inv = new Invoice__c(
            Name = 'TEST-12345',
            Account__c = acct.Id,
            Opportunity__c = opp.Id
        );

        insert inv;

        // create a file, unshared to any record
        ContentVersion file = new ContentVersion(
            Title = 'Invoice TEST-12345',
            PathOnClient = 'file.txt',
            VersionData = Blob.valueOf( 'Hello World' )
        );

        insert file;

        // query the generated content document id
        file = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id ];

        Test.startTest();

        // share the file to the account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = file.ContentDocumentId,
            LinkedEntityId = inv.Id,
            ShareType = 'I'
        );

                // create a second file, unshared to any record
                ContentVersion file2 = new ContentVersion(
                    Title = 'Invoice TEST-12345 V2',
                    PathOnClient = 'file.txt',
                    VersionData = Blob.valueOf( 'Hello World' )
                );
        
                insert file2;
        
                // query the generated content document id
                file2 = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id ];
        
                // share the file to the account
                ContentDocumentLink cdl2 = new ContentDocumentLink(
                    ContentDocumentId = file2.ContentDocumentId,
                    LinkedEntityId = inv.Id,
                    ShareType = 'I'
                );

        insert cdl2; // trigger fires

        Test.stopTest();


    }

}
