class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.text :description, null: false, default: ""

      t.timestamps
    end
  end
end
