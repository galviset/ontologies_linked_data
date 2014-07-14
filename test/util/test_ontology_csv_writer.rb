require_relative '../models/test_ontology_common'
require 'csv'

class TestOntologyCSVWriter < LinkedData::TestOntologyCommon

  # CSV column headers
  CLASS_ID = 'Class ID'
  PREFERRED_LABEL = 'Preferred Label'
  SYNONYMS = 'Synonyms'
  DEFINITIONS = 'Definitions'
  CUI = 'CUI'
  SEMANTIC_TYPES = 'Semantic Types'
  OBSOLETE = 'Obsolete'
  PARENTS = 'Parents'

  def self.before_suite
    @@acronym = 'CSV_TEST_BRO'
    sub_id = 1

    # Directory for storing CSV output.
    @@path_to_repo = File.join([LinkedData.settings.repository_folder, @@acronym, sub_id.to_s])
    if not Dir.exist? @@path_to_repo
      FileUtils.mkdir_p @@path_to_repo
    end

    # Create a test ontology submission.
    self.new('self').submission_parse(@@acronym, 'CSV TEST BRO', 
      './test/data/ontology_files/BRO_for_csv.owl', sub_id, 
      process_rdf: true, index_search: false, run_metrics: false, reasoning: true)
    sub = LinkedData::Models::OntologySubmission.where(ontology: [acronym: @@acronym], submissionId: sub_id).include(:version).first

    # Open the CSV writer.
    writer = LinkedData::Utils::OntologyCSVWriter.new
    writer.open(@@path_to_repo, @@acronym)

    # Write out the CSV.
    page = 1
    size = 2500
    @@num_classes = 0
    props_to_include = LinkedData::Models::Class.goo_attrs_to_load() << :parents
    paging = LinkedData::Models::Class.in(sub).include(props_to_include).page(page, size)

    while !page.nil?
      page_classes = paging.page(page, size).all
      
      page_classes.each do |c|
        writer.write_class(c)
      end
      
      @@num_classes += page_classes.length
      page = page_classes.next? ? page + 1 : nil
    end

    writer.close
  end

  def get_path_to_csv
    return File.join(@@path_to_repo, @@acronym + '.gz')
  end

  def get_csv_string
    gz = Zlib::GzipReader.open(get_path_to_csv)
    return gz.read
  end

  def test_csv_writer_valid
    assert File.file?(get_path_to_csv)
  end

  def test_csv_writer_row_count
    classes = CSV.parse(get_csv_string, headers:true)
    assert_equal true, @@num_classes == classes.count
  end

  def test_csv_writer_content_id
    class_exists = false
    preferred_label = 'Fabrication Facility'
    id = 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Fabrication_Facility'

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal id, row[CLASS_ID]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end  

  def test_csv_writer_content_preferred_label
    class_exists = false
    preferred_label = 'Funding Resource'
    id = 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Funding_Resource'

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[CLASS_ID] == id
        assert_equal preferred_label, row[PREFERRED_LABEL]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_synonym
    class_exists = false
    preferred_label = 'Database'
    synonym = 'Data Repository'

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal synonym, row[SYNONYMS]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_synonym_multiple
    class_exists = false
    preferred_label = 'Bioinformatics'
    synonyms = ['Bioinformatics synonym 1', 'Bioinformatics synonym 2', 'Bioinformatics synonym 3']

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal synonyms, row[SYNONYMS].split('|').sort
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_definition
    class_exists = false
    preferred_label = 'Fabrication Facility'
    definition = 'A defintion added for testing CSV generation.'

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal definition, row[DEFINITIONS]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_definition_multiple
    class_exists = false
    preferred_label = 'Data Storage Service'
    definitions = ['Test definition A', 'Test definition B', 'Test definition C']

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal definitions, row[DEFINITIONS].split('|').sort
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_cui
    class_exists = false
    preferred_label = 'Software Development'
    cui = 'C0150959'
    
    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal cui, row[CUI]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_cui_multiple
    class_exists = false
    preferred_label = 'Social Networking'
    cuis = ['C0000001', 'C0000002', 'C0000003']

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal cuis, row[CUI].split('|').sort
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_semantic_type
    class_exists = false
    preferred_label = 'Social Networking'
    semantic_type = 'http://bioontology.org/ontologies/Activity.owl#Activity'
    
    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal semantic_type, row[SEMANTIC_TYPES]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_semantic_type_multiple
    class_exists = false
    preferred_label = 'Genomics'
    semantic_types = ['http://bioontology.org/ontologies/Activity.owl#Activity', 
                      'http://bioontology.org/ontologies/Activity.owl#Gene_Therapy',
                      'http://bioontology.org/ontologies/ResearchArea.owl#Area_of_Research']

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal semantic_types, row[SEMANTIC_TYPES].split('|').sort
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_obsolete
    class_exists = false
    preferred_label = 'High Dimensional Data'
    
    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert row[OBSOLETE]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end  

  def test_csv_writer_content_non_obsolete
    class_exists = false
    preferred_label = 'Area of Research'
    
    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal 'false', row[OBSOLETE]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_parent
    class_exists = false
    preferred_label = 'Deep Parsing'
    parent_id = 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Parsing'
    
    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal parent_id, row[PARENTS]
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

  def test_csv_writer_content_parent_multiple
    class_exists = false
    preferred_label = 'Technical Support'
    parent_ids = ['http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#People_Resource', 
                  'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Service_Resource']

    classes = CSV.parse(get_csv_string, headers:true)
    classes.select do |row|
      if row[PREFERRED_LABEL] == preferred_label
        assert_equal parent_ids, row[PARENTS].split('|').sort
        class_exists = true
      end
    end

    assert class_exists, %Q<Class not found: "#{preferred_label}">
  end

end