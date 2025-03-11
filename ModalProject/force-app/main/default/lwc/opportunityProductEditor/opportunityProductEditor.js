import { api, track } from 'lwc';
import { showToast } from 'c/commonUtils';
import OpportunitySelectionData from 'c/opportunitySelectionData';

export default class OpportunityProductEditor extends OpportunitySelectionData {
    // 商品編集画面のヘッダー行
    columnsAdd = [
        { label: '商品名', fieldName: 'Name', type: 'text', editable: false },
        { label: '数量', fieldName: 'Quantity', type: 'number', editable: true,
            typeAttributes: { minimumFractionDigits: '2' } 
        },
        { label: '原価', fieldName: 'CostPrice', type: 'currency', editable: false },
        { label: '販売価格', fieldName: 'UnitPrice', type: 'currency', editable: true },
        { label: '割引（パーセント）', fieldName: 'Discount', type: 'number', editable: true, 
            typeAttributes: { step: '0.01' } },
        {
            type: 'button-icon',
            typeAttributes: {
            iconName: 'utility:delete',
            name: 'delete',
            rowId: { fieldName: 'id' },
            alternativeText: '削除',
            size: 'small',
            variant: 'bare',
            }
        }
    ];
    
    @api selectedProducts;        // 商品選択用のデータ
    @track secondTableData;       // 編集用のデータ
    @track draftValues = [];      // インライン編集の値を保持
    @track updatedValues = [];    // 編集された後のデータ行
    isFirstOpen = false;          // 商品選択画面
    isSecondOpen = true;          // 商品選択画面
    hideCheckboxColumn2 = true;   // 画面のチェックボックス

    connectedCallback() {
        if (Array.isArray(this.selectedProducts) && this.selectedProducts.length > 0) {
            this.secondTableData = [...this.selectedProducts.map(product => ({
                ...product,
                Quantity: product.Quantity || 1,
                Discount: product.Discount || 0
            }))];
        } else {
            console.warn('selectedProductsは 空か undefined です。');
        }
    }

    // 削除ボタンの処理
    deleteRowAction(event) {
        const rowId = event.detail.row.Id;
        this.secondTableData = this.secondTableData.filter(item => item.Id !== rowId);
        this.dispatchEvent(showToast('成功', '商品が削除されました。', 'success'));
    }

    // インライン編集の処理
    handleCellChange(event) {
        const updatedValues = event.detail.draftValues;
        let newData = [...this.secondTableData];
    
        updatedValues.forEach(update => {
            let row = newData.find(item => item.Id === update.Id);
            if (row) {
                Object.keys(update).forEach(key => {
                    if (['Discount', 'Quantity', 'CostPrice', 'UnitPrice'].includes(key)) {
                        row[key] = update[key] != null && !isNaN(Number(update[key])) ? Number(update[key]) : 0;
                    } else {
                        row[key] = update[key];
                    }
                });
            }
        });

        // 更新後の配列を代入し、コンポーネントの再描画を促す
        this.secondTableData = newData; 
    
        // 変更後に draftValues をクリア
        this.draftValues = [];
    }

    // 保存ボタンのクリック処理
    @api
    handleSave() {
        if (!Array.isArray(this.secondTableData) || this.secondTableData.length === 0) {
            this.dispatchEvent(showToast('警告', '商品を選択してください。', 'warning'));
            return;
        }
        this.dispatchEvent(new CustomEvent('save', { detail: this.secondTableData }));
    }

    // データをリフレッシュ
    @api
    refreshData() {
        return super.refreshData()
            .then(() => console.log('親クラスの refreshData() 呼び出し完了'))
            .catch(error => console.error('親クラスの refreshData() 呼び出しエラー:', error));
    }
}
