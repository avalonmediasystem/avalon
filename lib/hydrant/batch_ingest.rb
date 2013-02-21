require 'iconv'
require 'hydrant/workflow/workflow_controller_behavior'
require 'hydrant/controller/controller_behavior'
require 'hydrant/dropbox'

module Hydrant
  module Batch

    include Hydrant::Controller::ControllerBehavior

    def self.ingest
      # Scans dropbox for new batch packages
      logger.debug "============================================"
      logger.debug "<< Starts scanning for new batch packages >>"
      
      #dropbox = Hydrant::Dropbox.new( Hydrant::Configuration['dropbox']['path'] )

      new_packages = Hydrant::DropboxService.find_new_packages
      logger.debug "<< Found #{new_packages.count} new packages >>"


      if new_packages.length > 0
        # Extracts package and process
        new_packages.each_with_index do |package, index|
          logger.debug "<< Processing package #{index} >>"

          media_objects = []
          email_address = package.manifest.email || Hydrant::Configuration['email']['notification']

          package.validate do |entry|
            mo = MediaObject.new
            mo.update_datastream(:descMetadata, entry.fields)
            mo
          end

          if package.valid?
            package.process do |fields, files, opts, entry|
              # Creates and processes MasterFiles
              mediaobject = MediaObjectsController.initialize_media_object(package.manifest.email || 'batch')
              mediaobject.workflow.origin = 'batch'
              mediaobject.save(:validate => false)
              logger.debug "<< Created MediaObject #{mediaobject.pid} >>"

              # Simluate the uploading of the files using the workflow step so that
              # changes only have to be made in one place. This may mean some
              # refactoring of the master_file_controller class eventually.
              files.each do |file_path|
                mf = MasterFile.create
                mf.mediaobject = mediaobject
                mf.setContent(File.open(file_path, 'rb'))
                if mf.save
                  mediaobject.save(validate: false)
                  logger.debug "<< Created and associated MasterFile #{mf.pid} >>"
                  mf.process
                end
              end

              context = {mediaobject: mediaobject}
              context = HYDRANT_STEPS.get_step('file-upload').execute context

              # temporary change, method in media object for updating datastream
              # currently takes class attributes instead of meta data attributes
              fields[:title] = fields.delete(:main_title)

              context = {mediaobject: mediaobject, media_object: fields}
              context = HYDRANT_STEPS.get_step('resource-description').execute context

              # Here we need to skip the structure step and go straight to the
              # permissions. Structure is implicit from the order the files were
              # listed in the batch manifest
              #
              # Afterwards, if the auto-publish flag is true then publish the
              # media objects. In either case here is where the notifications
              # should take place
              context = {media_object: { pid: mediaobject.pid, hidden: opts[:hidden] ? '1' : nil, access: 'private' }, mediaobject: mediaobject, user: 'batch'}
              context = HYDRANT_STEPS.get_step('access-control').execute context

              mediaobject.workflow.last_completed_step = 'access-control'

              if opts[:publish]
                mediaobject.publish!(email_address)
                mediaobject.workflow.publish
              end

              if mediaobject.save
                logger.debug "Done processing package #{index}"
              else
                logger.debug "Problem saving MediaObject"
              end

              media_objects << mediaobject
            end
            # send email confirming kickoff of batch
            IngestBatchMailer.batch_ingest_validation_success( package ).deliver
          else
            package.manifest.error!
            IngestBatchMailer.batch_ingest_validation_error( package ).deliver
          end

          # Create an ingest batch object for 
          # all of the media objects associated with this 
          # particular package
          IngestBatch.create( 
            media_object_ids: media_objects.map(&:id), 
            name:  package.manifest.name,
            email: email_address,
          ) if media_objects.length > 0

        end
      end
    end
  end
end
