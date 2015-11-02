SubjectStructureBuilder = Struct.new(:item) do
  def call(hash)
    Subject.transaction do
      recurse(item  .subjects.root, hash)
    end
  end

private

  def recurse(parent, hash)
    return if hash.nil?
    hash.each do |subject_name, children|
      subject = find_or_create_subject(subject_name, parent)
      recurse(subject, children)
    end
  end

  def subject_attributes(name, parent)
    {
      :name => name,
      :parent_id => parent.id,
      :item_id => item  .id
    }
  end

  def find_or_create_subject(name, parent)
    attributes = subject_attributes(name, parent)
    Subject.where(attributes).first || Subject.create!(attributes)
  end
end
