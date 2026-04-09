class CreateGenerationRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :generation_requests do |t|
      t.string :skill, null: false, default: ""
      t.string :topic, null: false, default: ""

      t.timestamps
    end
  end
end
