class CreateTreks < ActiveRecord::Migration
  def change
    create_table :treks do |t|
      t.string :title
      t.references :user

      t.timestamps
    end
    add_index :treks, :user_id
  end
end
