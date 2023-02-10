require 'spec_helper'

require_relative '../../../../../lib/locomotive/steam/adapters/filesystem/yaml_loader.rb'
require_relative '../../../../../lib/locomotive/steam/adapters/filesystem/yaml_loaders/content_entry.rb'

describe Locomotive::Steam::Adapters::Filesystem::YAMLLoaders::ContentEntry do

  let(:site_path)     { default_fixture_site_path }
  let(:content_type)  { instance_double('Bands', _id: 42, slug: 'bands', association_fields: [], select_fields: [], file_fields: [], password_fields: []) }
  let(:scope)         { instance_double('Scope', locale: :en, context: { content_type: content_type }) }
  let(:loader)        { described_class.new(site_path) }

  describe '#load' do

    subject { loader.load(scope).sort { |a, b| a[:_label] <=> b[:_label] } }

    it 'tests various stuff' do
      expect(subject.size).to eq 3
      expect(subject.first[:_label]).to eq 'Alice in Chains'
      expect(subject.first[:content_type]).to eq nil
    end

    context 'a content type with a belongs_to field' do

      let(:field)         { instance_double('Field', name: 'band', type: :belongs_to) }
      let(:content_type)  { instance_double('Songs', slug: 'songs', association_fields: [field], select_fields: [], file_fields: [], password_fields: []) }

      it 'adds a new attribute for the foreign key' do
        expect(subject.first[:band_id]).to eq 'pearl-jam'
        expect(subject.first[:band]).to eq nil
        expect(subject.first[:position_in_band]).to eq 0
      end

    end

    context 'a content type with a select field' do

      let(:options)       { instance_double('Options') }
      let(:field)         { instance_double('Field', name: 'kind', type: :select, select_options: options) }
      let(:content_type)  { instance_double('Bands', slug: 'bands', select_fields: [field], association_fields: [], file_fields: [], password_fields: []) }

      it 'adds a new attribute for the foreign key' do
        expect(options).to receive(:by_name).twice.with('grunge').and_return(instance_double('GrungeOption', _id: 0))
        expect(options).to receive(:by_name).with('rock').and_return(instance_double('RockOption', _id: 1))
        expect(subject.first[:kind_id]).to eq 0
        expect(subject.first[:kind]).to eq nil
      end

    end

    context 'a content type with a password field' do

      let(:field)         { instance_double('Field', name: 'password', type: :password) }
      let(:content_type)  { instance_double('Accounts', slug: 'accounts', select_fields: [], association_fields: [], file_fields: [], password_fields: [field]) }

      it 'adds a new attribute for the hashed password' do
        expect(subject.first[:password_hash]).not_to eq 'easyone'
        expect(subject.first[:password]).to eq nil
      end

    end

    context 'a content type with a localized field' do

      let(:options_scope) { instance_double('Scope', :locale= => true) }
      let(:options)       { instance_double('SelectOptionsRepository', scope: options_scope) }
      let(:field)         { instance_double('Field', name: 'category', type: :select, localized: true, select_options: options) }
      let(:content_type)  { instance_double('Updates', slug: 'updates', select_fields: [field], association_fields: [], file_fields: [], password_fields: []) }

      it 'adds a new localized attribute for the foreign key' do
        option = instance_double('Option', _id: 0)
        allow(options_scope).to receive(:with_locale) { |_, &block| block.call }
        allow(options).to receive(:by_name).with('General').and_return(option)
        allow(options).to receive(:by_name).with('Général').and_return(option)
        expect(subject.last[:category_id]).to eq({ en: 0, fr: 0 })
        expect(subject.last[:category]).to eq nil
      end

    end

    context 'a content type with a file field' do

      let(:field)         { instance_double('Field', name: 'cover', type: :file) }
      let(:content_type)  { instance_double('Songs', slug: 'songs', select_fields: [], association_fields: [], file_fields: [field], password_fields: []) }

      it 'stores the size of the file' do
        expect(subject.first[:cover_size]).to eq('default' => 14768)
      end

      it 'stores the size of the file in multiple locales' do
        expect(subject[1][:cover_size]).to eq('en' => 14768, 'fr' => 165883, 'nb' => 165883)
      end


    end

  end

end
