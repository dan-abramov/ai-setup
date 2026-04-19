class AddSolutionCodeToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :solution_code, :text, default: "", null: false
  end
end
