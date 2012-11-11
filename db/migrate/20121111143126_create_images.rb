class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :filename
      t.float :latitude
      t.float :longitude
      t.references :trek

      t.timestamps
    end
    add_index :images, :trek_id
  end
end
