RSpec.describe Yaks::Mapper::Form do
  let(:form)   { described_class.create( full_args ) }
  let(:name)      { :the_name }
  let(:full_args) { {name: name}.merge(args) }
  let(:args) {
    {
      action: '/foo',
      title: 'a title',
      method: 'PATCH',
      media_type: 'application/hal+json',
      fields: fields
    }
  }
  let(:fields) { [] }

  describe '.create' do
    it 'should have a name of nil when ommitted' do
      expect(described_class.create.name).to be_nil
    end
  end

  describe '#add_to_resource' do
    let(:resource) { form.new.add_to_resource(Yaks::Resource.new, Yaks::Mapper.new(nil), nil) }


    context 'with fields' do
      let(:fields) {
        [
          Yaks::Mapper::Form::Field.new(
            name: 'field name',
            label: 'field label',
            type: 'text',
            value: 7
          )
        ]
      }

    end
  end
end
