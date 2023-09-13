# hyrax_archivematica
Hyrax/Archivematica integration

A gem to integrate Hyrax to Archivematica. Records deposited or updated in Hyrax will be

- Assessed for significant changes (if updated)
- Packaged into bagit bags
- Transferred to an archivematica instance
- Transfer and ingest process instigated and tracked by series fo sidekiq jobs
- Progress of transfer and ingest process displayed in Hyrax work archive page
- AIP reference recorded against hyrax work

