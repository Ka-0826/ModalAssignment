import { track, api } from 'lwc';
import OpportunitySelectionData from 'c/opportunitySelectionData';
import { showToast } from 'c/commonUtils';

export default class OpportunityProductSelection extends OpportunitySelectionData {

    // 商品選択画面のヘッダー行
    columnsDatatable = [
        { label: '商品名', fieldName: 'Name', type: 'text' },
        { label: '商品コード', fieldName: 'ProductCode', type: 'text' },
        { label: '有効', fieldName: 'IsActive', type: 'boolean' },
        { label: '原価', fieldName: 'CostPrice', type: 'currency' },
        { label: '販売価格', fieldName: 'UnitPrice', type: 'currency' },
        { label: '商品分類1', fieldName: 'Category1', type: 'text' },
        { label: '商品分類2', fieldName: 'Category2', type: 'text' }
    ];

    @track selectedRows = [];    // 選択した商品
    @track selectedOption1 = ''; // 選択された商品分類1
    @track selectedOption2 = ''; // 選択された商品分類2
    isFirstOpen = true;          // 商品選択画面
    isSecondOpen = false;        // 商品編集画面
    hideCheckboxColumn1 = false; // 画面のチェックボックス

    connectedCallback() {
        this.template.addEventListener('gridupdate', event => {
            console.log('受信したデータ:', JSON.stringify(event.detail));
            this.gridData = event.detail;
            this.updateSelectedRows(this.selectedRows); // データ更新時に選択状態も更新
        });
    }

    // フィルター条件に基づいてデータを取得
    get filteredData() {
        let filtered = Array.isArray(this.gridData) ? [...this.gridData] : [];
    
        if (this.selectedOption1) {
            filtered = filtered.filter(item => item.Category1 === this.selectedOption1);
        }
    
        if (this.selectedOption2) {
            filtered = filtered.filter(item => item.Category2 === this.selectedOption2);
        }
    
        return filtered;
    }

    // 商品分類1の選択変更
    handleChange1(event) {
        this.selectedOption1 = event.detail.value;
        this.updateSelectedRows(this.filteredData); // フィルター変更時に選択状態を維持
    }

    // 商品分類2の選択変更
    handleChange2(event) {
        this.selectedOption2 = event.detail.value;
        this.updateSelectedRows(this.filteredData); // フィルター変更時に選択状態を維持
    }

    // 商品分類の選択をクリア
    handleClear() {
        this.selectedOption1 = '';
        this.selectedOption2 = '';
        this.updateSelectedRows(); // フィルター変更時に選択状態を維持
    }

    // 行の選択
    handleRowSelection(event) {
        if (!this.selectedRows) {
            this.selectedRows = [];
        }
        
        const selectedRows = event.detail.selectedRows;
        
        // 重複を避けて統合する
        const updatedSelectedRows = [...this.selectedRows, ...selectedRows];
        
        // 重複を削除（IDで一意にする）
        this.selectedRows = updatedSelectedRows.filter((row, index, self) =>
            index === self.findIndex(r => r.Id === row.Id) // Idのキー名を確認
        );
    }

    // 選択された行を更新
    updateSelectedRows(filtered) {
        if (!this.selectedRows) {
            this.selectedRows = [];
        }

        // 選択された行の Id を取得
        const selectedIds = this.selectedRows.map(row => row.Id);

        // フィルター後に表示される行の Id を取得
        const filteredIds = filtered.map(item => item.Id);

        // フィルター後に表示される行に関係なく、選択された行がそのまま維持される
        this.selectedRows = this.selectedRows.map(row => {
            if (selectedIds.includes(row.Id)) {
                // 選択されている行がフィルター後に表示される場合、その行を選択状態に保持
                return row;
            }
            // フィルター後に選択された（新しい選択対象）を追加
            if (filteredIds.includes(row.Id)) {
                return row;
            }
            return null;  // フィルター後に表示されない行は除外
        }).filter(row => row !== null);

        // 既に選択された行の ID とフィルター後に新たに選択された行を統合
        const newlySelectedRows = filtered.filter(item => selectedIds.includes(item.Id));

        // 新たに選択された行を選択状態にする
        this.selectedRows = [...this.selectedRows, ...newlySelectedRows];

        // 重複行の削除
        this.selectedRows = this.selectedRows.filter((row, index, self) =>
            index === self.findIndex(r => r.Id === row.Id)
        );
    }

    // 次へボタンのクリック処理
    @api
    handleNext() {
        if (this.selectedRows.length === 0) {
            this.dispatchEvent(showToast('警告', '商品を選択してください。', 'warning'));
            return;
        }

        // 選択された行を更新
        this.updateSelectedRows(this.filteredData);

        //選択された商品データをSecondTableData 配列にコピー
        this.secondTableData = [...this.selectedRows];

        // quoteLineItemContainerへ通知
        this.dispatchEvent(new CustomEvent('next', { detail: this.selectedRows }));
    }
}
