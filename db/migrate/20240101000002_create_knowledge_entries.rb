class CreateKnowledgeEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_entries do |t|
      t.string :title, null: false
      t.text :content
      t.integer :source_type, null: false, default: 0
      t.string :source_url
      t.references :knowledge_base, null: false, foreign_key: true

      t.timestamps
    end

    # 添加索引以提高搜索性能
    add_index :knowledge_entries, :title
    add_index :knowledge_entries, :source_type
  end
end
