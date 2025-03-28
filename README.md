# LWC実装課題（ModalProject）

## 概要
このプロジェクトは、Salesforceで見積のための機能を実装したものです。  
具体的には、LWC（Lightning Web Components）を使用して商品を選択し、見積金額を計算する機能を提供します。  
また、商談や価格表といった関連レコードからも商品を追加できるように実装しました。

### 主な機能
##### 見積機能
「見積」レコードページから「商品を選択」ボタンを押して、商品を追加し、見積もり金額を自動的に作成します。

##### 商談商品追加機能
「商談」レコードページから「商品を選択」ボタンを押して、商品を追加します。

##### 価格表エントリーマスターの追加機能
「価格表マスタ」レコードページから「商品を選択」ボタンを押して、商品を追加します。

### 使用技術
LWC (Lightning Web Components): Salesforceで使用されるコンポーネントフレームワーク。  
フロントエンドでユーザーインターフェースを作成します。  
Apex: Salesforceでのサーバーサイドプログラム。データベース操作やビジネスロジックの実行に使用します。  

### ファイル構成
##### Apex
OpportunityLineItemController.cls - 商談商品を管理するApexクラス  
OpportunityLineItemControllerTest.cls  - 商談商品を管理するApexテストクラス  
PricebookEntryController.cls - 価格表エントリーマスターを管理するApexクラス  
PricebookEntryControllerTest.cls - 価格表エントリーマスターを管理するApexテストクラス  
QuoteLineItemController.cls - 見積品目を管理するApexクラス  
QuoteLineItemControllerTest.cls - 見積品目を管理するApexテストクラス  

##### LWC
createOpportunityLineItem - 商談商品を作成するLWCコンポーネント  
├createOpportunityLineItem.html  
├createOpportunityLineItem.css  
├createOpportunityLineItem.js  
└createOpportunityLineItem.js-meta.xml  

createPricebookEntry - 価格表エントリーマスターを作成するLWCコンポーネント  
├createPricebookEntry.html  
├createPricebookEntry.css  
├createPricebookEntry.js  
└createPricebookEntry.js-meta.xml  

createQuoteLineItem - 見積品目を作成するLWCコンポーネント  
├createQuoteLineItem.html  
├createQuoteLineItem.css  
├createQuoteLineItem.js  
└createQuoteLineItem.js-meta.xml  

### 環境
Salesforce Developer Edition  
Salesforce CLI（sfdx）
Visual Studio Code（VSCode）

### 使い方
##### 見積機能
見積レコードページから「商品を選択」ボタンを押すと、商品を選択するインターフェースが表示されます。    
商品を選択すると、見積もり金額が自動的に作成されます。  

##### 商談商品追加機能
商談レコードページから「商品を選択」ボタンを押すと、商品を追加するインターフェースが表示されます。  
商品を選択すると、商談の金額が自動的に作成されます。  

##### 価格表エントリーマスター追加機能
価格表レコードページから「商品を選択」ボタンを押すと、商品を追加することができます。
