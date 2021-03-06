# -*- coding: utf-8 -*-

module Yaks
  class Format
    class HTML < self
      include Adamantium, Util

      register :html, :html, 'text/html'

      def template
        Hexp.parse(File.read(File.expand_path('../template.html', __FILE__)))
      end
      memoize :template

      def section(name)
        template.select(".#{name}").first
      end

      def serialize_resource(resource)
        template.replace('body') do |body|
          body.content(render_resource(resource))
        end
      end

      def render_resource(resource, templ = section('resource'))
        templ
          .replace('.type') { |header| header.content(resource.type.to_s + (resource.collection? ? ' collection' : '')) }
          .replace('.attribute', &render_attributes(resource.attributes))
          .replace('.links') {|links| resource.links.empty? ? [] : links.replace('.link', &render_links(resource.links)) }
          .replace('.forms') {|div| render_forms(resource.forms).call(div) }
          .replace('.subresource') {|sub_templ| render_subresources(resource, templ, sub_templ) }
      end

      def render_attributes(attributes)
        ->(templ) do
          attributes.map do |key, value|
            templ
              .replace('.name')  {|x| x.content(key.to_s) }
              .replace('.value') {|x| x.content(value.inspect) }
          end
        end
      end

      def render_links(links)
        ->(templ) do
          links.map do |link|
            templ
              .replace('.rel a') {|a| a.attr('href', link.rel.to_s).content(link.rel.to_s) }
              .replace('.uri a') {|a| a.attr('href', link.uri).content(link.uri) }
              .replace('.title') {|x| x.content(link.title.to_s) }
              .replace('.templated') {|x| x.content(link.templated?.inspect) }
          end
        end
      end

      def render_subresources(resource, templ, sub_templ)
        templ = templ.replace('h1,h2,h3,h4') {|h| h.set_tag("h#{h.tag[/\d/].to_i.next}") }
        if resource.collection?
          resource.seq.map do |r|
            render_resource(r, templ)
          end
        else
          resource.subresources.map do |resources|
            rel = resources.rels.first.to_s
            sub_templ
              .replace('.rel a') {|a| a.attr('href', rel).content(rel) }
              .replace('.value') {|x| x.content(resources.seq.map { |resource| render_resource(resource, templ) })}
          end
        end
      end


      def render_forms(forms)
        ->(div) do
          div.content(
            forms.map(&method(:render_form))
          )
        end
      end

      def render_form(form_control)
        form = H[:form]
        form = form.attr('name', form_control.name)          if form_control.name
        form = form.attr('method', form_control.method)      if form_control.method
        form = form.attr('action', form_control.action)      if form_control.action
        form = form.attr('enctype', form_control.media_type) if form_control.media_type

        rows = form_control.fields.map(&method(:render_field))

        form.content(H[:table, form_control.title || '', *rows, H[:tr, H[:td, H[:input, {type: 'submit'}]]]])
      end

      def render_field(field)
        return render_fieldset(field) if field.type == :fieldset
        extra_info = reject_keys(field.to_h_compact, :type, :name, :value, :label, :options)
        H[:tr,
          H[:td,
            H[:label, {for: field.name}, [field.label, field.required ? '*' : ''].join]],
          H[:td,
            case field.type
            when /select/
              H[:select, reject_keys(field.to_h_compact, :options), render_select_options(field.options)]
            when /textarea/
              H[:textarea, reject_keys(field.to_h_compact, :value), field.value || '']
            when /legend/
              H[:legend, field.to_h_compact]
            else
              H[:input, field.to_h_compact]
            end],
          H[:td, extra_info.empty? ? '' : extra_info.inspect]
         ]
      end

      def render_fieldset(fieldset)
        H[:fieldset, fieldset.fields.map(&method(:render_field))]
      end

      def render_select_options(options)
        options.map do |o|
          H[:option, reject_keys(o.to_h_compact, :label), o.label]
        end
      end
    end
  end
end
