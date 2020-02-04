# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class IuApiController < ApplicationController

  # GET /iu_api/media_object_structure?id=1
  def media_object_structure
    media_object = MediaObject.find(params[:id])
    authorize! :edit, media_object
    csv_string = CSV.generate(headers: ['Label', 'MDPI Barcode', 'Masterfile ID', 'Order', 'Structure XML Filename'], write_headers: true) do |csv|
      media_object.ordered_master_files.to_a.each_with_index do |master_file, index|
        barcode = master_file.identifier.find { |id| id =~ /^\d{14}$/ }
        csv << [master_file.title, barcode, master_file.id, index, '']
      end
    end
    render plain: csv_string, content_type: 'text/csv'
  end

  # PUT /iu_api/media_object_structure?id=1
  def media_object_structure_update
    media_object = MediaObject.find(params[:id])
    authorize! :edit, media_object
    csv_string = params[:csv].read
    parsed_csv = CSV.parse(csv_string)
    array_of_rows = parsed_csv[1..parsed_csv.size]
    
    if params[:structure]
      array_of_rows.each do |csv|
        master_file = MasterFile.find(csv[2])
        xml = params[:structure].find { |f| f.original_filename == csv[4] }
        next unless xml
        master_file.structuralMetadata.content = xml
        master_file.save!
      end
    end
    
    new_section_order = array_of_rows.sort_by { |row| row[3].to_i }.collect { |row| row[2] }
    if new_section_order != media_object.ordered_master_file_ids
      media_object.ordered_master_files = new_section_order.collect { |id| MasterFile.find(id) }
      media_object.save!
    end

    head :ok
  end

end