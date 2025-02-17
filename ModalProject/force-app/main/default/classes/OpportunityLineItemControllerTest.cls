@isTest
private class OpportunityLineItemControllerTest {
    
    @testSetup
    static void setupTestData() {
        // 商品分類1の値を取得
        List<String> category1Values = new List<String>();
        for (Schema.PicklistEntry entry : Product2.Category1__c.getDescribe().getPicklistValues()) {
            category1Values.add(entry.getValue());
        }

        // 商品分類2の値を取得
        List<String> category2Values = new List<String>();
        for (Schema.PicklistEntry entry : Product2.Category2__c.getDescribe().getPicklistValues()) {
            category2Values.add(entry.getValue());
        }

        // デフォルト値を取得（選択肢がない場合に備えてリストの先頭を使用）
        String category1Value = category1Values.isEmpty() ? null : category1Values[0];
        String category2Value = category2Values.isEmpty() ? null : category2Values[0];

        // 価格表マスタ のテストデータ作成
        Pricebook__c pricebook = new Pricebook__c(
            Name = 'Test Pricebook',
            IsActive__c = true
        );
        insert pricebook;

        // 商品 のテストデータ作成
        Product2 product = new Product2(
            Name = 'Test Product',
            Category1__c = category1Value,
            Category2__c = category2Value,
            IsActive = true
        );
        insert product;

        // 価格表エントリーマスタ のテストデータ作成
        PricebookEntryMaster__c pricebookEntry = new PricebookEntryMaster__c(
            Pricebook__c = pricebook.Id,
            Product2__c = product.Id,
            UnitPrice__c = 100,
            IsActive__c = true,
            Category1__c = category1Value,
            Category2__c = category2Value,
            CostPrice__c = 50
        );
        insert pricebookEntry;

        // 商談 のテストデータ作成
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Pricebook__c = pricebook.Id
        );
        insert opp;
    }

    @isTest
    static void testGetOpportunityPricebookEntries() {
        // テストデータ取得
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        // Apex メソッドを呼び出し
        Test.startTest();
        List<PricebookEntryMaster__c> entries = OpportunityLineItemController.getOpportunityPricebookEntries(testOpp.Id);
        Test.stopTest();

        // 検証
        System.assertNotEquals(entries, null, '取得した価格表エントリが null です');
        System.assertEquals(1, entries.size(), '取得した価格表エントリの数が期待値と異なります');

        // 異常系: 存在しない 商談ID
        List<PricebookEntryMaster__c> emptyEntries = OpportunityLineItemController.getOpportunityPricebookEntries('InvalidId');
        System.assertEquals(0, emptyEntries.size(), '無効なIDでエントリが取得されるべきではありません');
    }

    @isTest
    static void testGetCategoryOptions() {
        Test.startTest();
        Map<String, List<String>> categoryMap = OpportunityLineItemController.getCategoryOptions();

        // 商談分類リストを取得
        List<String> categoryOptions = categoryMap.containsKey('菓子') ? categoryMap.get('チョコ') : new List<String>();

        Test.stopTest();

        // 検証
        System.assertNotEquals(categoryOptions, null, '商品分類が null です');
        System.assert(categoryOptions.size() > 0, '商品分類が1つ以上あるべきです');
    }

    @isTest
    static void testCreateLineItems() {
        // テストデータ取得
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntryMaster__c testEntry = [SELECT Id, Product2__c FROM PricebookEntryMaster__c LIMIT 1];

        // 商談商品 のテストデータ作成
        OpportunityLineItemMaster__c lineItem = new OpportunityLineItemMaster__c(
            Opportunity__c = testOpp.Id,
            Product2__c = testEntry.Product2__c,
            UnitPrice__c = 100,
            Quantity__c = 1
        );

        List<OpportunityLineItemMaster__c> lineItems = new List<OpportunityLineItemMaster__c>{ lineItem };

        // Apex メソッドを呼び出し
        Test.startTest();
        List<OpportunityLineItemMaster__c> createdItems = OpportunityLineItemController.createLineItems(lineItems);
        Test.stopTest();

        // 検証
        System.assertNotEquals(createdItems, null, '作成された商談商品が null です');
        System.assertEquals(1, createdItems.size(), '作成された商談商品の数が期待値と異なります');

        // 異常系: `null` のリスト
        List<OpportunityLineItemMaster__c> nullResult = OpportunityLineItemController.createLineItems(null);
        System.assertEquals(0, nullResult.size(), 'nullの入力でエントリが作成されるべきではありません');

        // 異常系: 商品 が `null` のデータ
        OpportunityLineItemMaster__c invalidLineItem = new OpportunityLineItemMaster__c(
            Opportunity__c = testOpp.Id,
            Product2__c = null,
            UnitPrice__c = 100,
            Quantity__c = 1
        );

        Test.startTest();
        try {
            OpportunityLineItemController.createLineItems(new List<OpportunityLineItemMaster__c>{ invalidLineItem });
            System.assert(false, '商品がnullの場合、例外が発生するべきです');
        } catch (Exception e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getTypeName(), '期待される例外が発生しませんでした');
        }
        Test.stopTest();
    }
}
