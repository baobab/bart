require 'action_controller/test_process'
require 'action_controller/integration' 
require 'action_controller/assertions'

class Successify
  include Test::Unit::Assertions

  attr_accessor :session 

  def initialize
    @session = ActionController::Integration::Session.new    
  end

  def add_all_patients_to_program
    User.current_user = User.find(5)
    Location.current_location = Location.find(701)
    hiv_program = Program.find_by_name("HIV")
    Patient.find(:all).collect{|patient| patient.add_programs([hiv_program]) }
  end

  # Maybe patients need to be class vars, for some reason it just disappears!  
  def test_scan_every_patient
    patient_ids = Patient.find(:all).map(&:id)
    login
    select_tasks ['HIV Reception']
    patient_ids.each {|patient_id|
      begin
        patient = Patient.find(patient_id)
        puts "Scanning #{patient.national_id} (#{patient.id})"
        scan_patient(patient.national_id, patient.id) 
        assert_redirected_to "/patient/patient_detail_summary"
      rescue Exception => e
        puts "  #{e}"
        yell "  #{e}"
      end
    }  
  end
  
  def test_every_mastercard
    patient_ids = Patient.find(:all).map(&:id)
    login
    select_tasks ['HIV Reception']
    patient_ids.each {|patient_id|
      begin
        patient = Patient.find(patient_id)
        puts "Scanning #{patient.national_id} (#{patient.id})"
        scan_patient(patient.national_id, patient.id) 
        assert_redirected_to "/patient/patient_detail_summary"
      rescue Exception => e
        puts "  #{e}"
        yell "  #{e}"
      end
    }  
  end
  
protected
  
  def login(username = :mikmck, password = :mike)
    session.post "/user/login", "user[username]" => "#{username}", "user[password]" => "#{password}"
  end

  def select_tasks(activities = nil)
    activities = Privilege.find(:all).map(&:privilege) unless activities
    session.post "/user/change_activities", "user[activities]" => activities
  end

  def scan_patient(identifier, patient_id = nil)
    session.get "/encounter/scan", "barcode" => identifier
    set_patient(patient_id) unless patient_id.blank?
  end
  
  def set_patient(patient_id)
    session.get "/patient/set_patient/#{patient_id}"
  end
  
private

      # Asserts that the response is one of the following types:
      # 
      # * <tt>:success</tt>: Status code was 200
      # * <tt>:redirect</tt>: Status code was in the 300-399 range
      # * <tt>:missing</tt>: Status code was 404
      # * <tt>:error</tt>:  Status code was in the 500-599 range
      #
      # You can also pass an explicit status code number as the type, like assert_response(501)
      def assert_response(type, message = nil)
        raise "#{@session.response.body}" if @session.response.response_code == 500
        clean_backtrace do
          if [ :success, :missing, :redirect, :error ].include?(type) && @session.response.send("#{type}?")
            assert_block("") { true } # to count the assertion
          elsif type.is_a?(Fixnum) && @session.response.response_code == type
            assert_block("") { true } # to count the assertion
          else
            assert_block(build_message(message, "Expected response to be a <?>, but was <?>", type, @session.response.response_code)) { false }
          end               
        end
      end

      # Assert that the redirection options passed in match those of the redirect called in the latest action. This match can be partial,
      # such that assert_redirected_to(:controller => "weblog") will also match the redirection of 
      # redirect_to(:controller => "weblog", :action => "show") and so on.
      def assert_redirected_to(options = {}, message=nil)
        clean_backtrace do
          assert_response(:redirect, message)

          if options.is_a?(String)
            msg = build_message(message, "expected a redirect to <?>, found one to <?>", options, @session.response.redirect_url)
            url_regexp = %r{^(\w+://.*?(/|$|\?))(.*)$}
            eurl, epath, url, path = [options, @session.response.redirect_url].collect do |url|
              u, p = (url_regexp =~ url) ? [$1, $3] : [nil, url]
              [u, (p[0..0] == '/') ? p : '/' + p]
            end.flatten

            assert_equal(eurl, url, msg) if eurl && url
            assert_equal(epath, path, msg) if epath && path 
          else
            @session.response_diff = options.diff(@session.response.redirected_to) if options.is_a?(Hash) && @session.response.redirected_to.is_a?(Hash)
            msg = build_message(message, "response is not a redirection to all of the options supplied (redirection is <?>)#{', difference: <?>' if @session.response_diff}", 
                                @session.response.redirected_to || @session.response.redirect_url, @session.response_diff)

            assert_block(msg) do
              if options.is_a?(Symbol)
                @session.response.redirected_to == options
              else
                options.keys.all? do |k|
                  if k == :controller then options[k] == ActionController::Routing.controller_relative_to(@session.response.redirected_to[k], @controller.class.controller_path)
                  else options[k] == (@session.response.redirected_to[k].respond_to?(:to_param) ? @session.response.redirected_to[k].to_param : @session.response.redirected_to[k] unless @session.response.redirected_to[k].nil?)
                  end
                end
              end
            end
          end
        end
      end

      # Asserts that the request was rendered with the appropriate template file.
      def assert_template(expected = nil, message=nil)
        clean_backtrace do
          rendered = expected ? @session.response.rendered_file(!expected.include?('/')) : @session.response.rendered_file
          msg = build_message(message, "expecting <?> but rendering with <?>", expected, rendered)
          assert_block(msg) do
            if expected.nil?
              !@session.response.rendered_with_file?
            else
              expected == rendered
            end
          end               
        end
      end

      # Asserts that the routing of the given path was handled correctly and that the parsed options match.
      def assert_recognizes(expected_options, path, extras={}, message=nil)
        clean_backtrace do 
          path = "/#{path}" unless path[0..0] == '/'
          # Load routes.rb if it hasn't been loaded.
          ActionController::Routing::Routes.reload if ActionController::Routing::Routes.empty? 
      
          # Assume given controller
          request = ActionController::TestRequest.new({}, {}, nil)
          request.path = path
          ActionController::Routing::Routes.recognize!(request)
      
          expected_options = expected_options.clone
          extras.each_key { |key| expected_options.delete key } unless extras.nil?
      
          expected_options.stringify_keys!
          msg = build_message(message, "The recognized options <?> did not match <?>", 
              request.path_parameters, expected_options)
          assert_block(msg) { request.path_parameters == expected_options }
        end
      end

      # Asserts that the provided options can be used to generate the provided path.
      def assert_generates(expected_path, options, defaults={}, extras = {}, message=nil)
        clean_backtrace do 
          expected_path = "/#{expected_path}" unless expected_path[0] == ?/
          # Load routes.rb if it hasn't been loaded.
          ActionController::Routing::Routes.reload if ActionController::Routing::Routes.empty? 
      
          generated_path, extra_keys = ActionController::Routing::Routes.generate(options, extras)
          found_extras = options.reject {|k, v| ! extra_keys.include? k}

          msg = build_message(message, "found extras <?>, not <?>", found_extras, extras)
          assert_block(msg) { found_extras == extras }
      
          msg = build_message(message, "The generated path <?> did not match <?>", generated_path, 
              expected_path)
          assert_block(msg) { expected_path == generated_path }
        end
      end

      # Asserts that path and options match both ways; in other words, the URL generated from 
      # options is the same as path, and also that the options recognized from path are the same as options
      def assert_routing(path, options, defaults={}, extras={}, message=nil)
        assert_recognizes(options, path, extras, message)
        
        controller, default_controller = options[:controller], defaults[:controller] 
        if controller && controller.include?(?/) && default_controller && default_controller.include?(?/)
          options[:controller] = "/#{controller}"
        end
         
        assert_generates(path, options, defaults, extras, message)
      end

      # Asserts that there is a tag/node/element in the body of the response
      # that meets all of the given conditions. The +conditions+ parameter must
      # be a hash of any of the following keys (all are optional):
      #
      # * <tt>:tag</tt>: the node type must match the corresponding value
      # * <tt>:attributes</tt>: a hash. The node's attributes must match the
      #   corresponding values in the hash.
      # * <tt>:parent</tt>: a hash. The node's parent must match the
      #   corresponding hash.
      # * <tt>:child</tt>: a hash. At least one of the node's immediate children
      #   must meet the criteria described by the hash.
      # * <tt>:ancestor</tt>: a hash. At least one of the node's ancestors must
      #   meet the criteria described by the hash.
      # * <tt>:descendant</tt>: a hash. At least one of the node's descendants
      #   must meet the criteria described by the hash.
      # * <tt>:sibling</tt>: a hash. At least one of the node's siblings must
      #   meet the criteria described by the hash.
      # * <tt>:after</tt>: a hash. The node must be after any sibling meeting
      #   the criteria described by the hash, and at least one sibling must match.
      # * <tt>:before</tt>: a hash. The node must be before any sibling meeting
      #   the criteria described by the hash, and at least one sibling must match.
      # * <tt>:children</tt>: a hash, for counting children of a node. Accepts
      #   the keys:
      #   * <tt>:count</tt>: either a number or a range which must equal (or
      #     include) the number of children that match.
      #   * <tt>:less_than</tt>: the number of matching children must be less
      #     than this number.
      #   * <tt>:greater_than</tt>: the number of matching children must be
      #     greater than this number.
      #   * <tt>:only</tt>: another hash consisting of the keys to use
      #     to match on the children, and only matching children will be
      #     counted.
      # * <tt>:content</tt>: the textual content of the node must match the
      #     given value. This will not match HTML tags in the body of a
      #     tag--only text.
      #
      # Conditions are matched using the following algorithm:
      #
      # * if the condition is a string, it must be a substring of the value.
      # * if the condition is a regexp, it must match the value.
      # * if the condition is a number, the value must match number.to_s.
      # * if the condition is +true+, the value must not be +nil+.
      # * if the condition is +false+ or +nil+, the value must be +nil+.
      #
      # Usage:
      #
      #   # assert that there is a "span" tag
      #   assert_tag :tag => "span"
      #
      #   # assert that there is a "span" tag with id="x"
      #   assert_tag :tag => "span", :attributes => { :id => "x" }
      #
      #   # assert that there is a "span" tag using the short-hand
      #   assert_tag :span
      #
      #   # assert that there is a "span" tag with id="x" using the short-hand
      #   assert_tag :span, :attributes => { :id => "x" }
      #
      #   # assert that there is a "span" inside of a "div"
      #   assert_tag :tag => "span", :parent => { :tag => "div" }
      #
      #   # assert that there is a "span" somewhere inside a table
      #   assert_tag :tag => "span", :ancestor => { :tag => "table" }
      #
      #   # assert that there is a "span" with at least one "em" child
      #   assert_tag :tag => "span", :child => { :tag => "em" }
      #
      #   # assert that there is a "span" containing a (possibly nested)
      #   # "strong" tag.
      #   assert_tag :tag => "span", :descendant => { :tag => "strong" }
      #
      #   # assert that there is a "span" containing between 2 and 4 "em" tags
      #   # as immediate children
      #   assert_tag :tag => "span",
      #              :children => { :count => 2..4, :only => { :tag => "em" } } 
      #
      #   # get funky: assert that there is a "div", with an "ul" ancestor
      #   # and an "li" parent (with "class" = "enum"), and containing a 
      #   # "span" descendant that contains text matching /hello world/
      #   assert_tag :tag => "div",
      #              :ancestor => { :tag => "ul" },
      #              :parent => { :tag => "li",
      #                           :attributes => { :class => "enum" } },
      #              :descendant => { :tag => "span",
      #                               :child => /hello world/ }
      #
      # <strong>Please note</strong: #assert_tag and #assert_no_tag only work
      # with well-formed XHTML. They recognize a few tags as implicitly self-closing
      # (like br and hr and such) but will not work correctly with tags
      # that allow optional closing tags (p, li, td). <em>You must explicitly
      # close all of your tags to use these assertions.</em>
      def assert_tag(*opts)
        clean_backtrace do
          opts = opts.size > 1 ? opts.last.merge({ :tag => opts.first.to_s }) : opts.first
          tag = find_tag(opts)
          assert tag, "expected tag, but no tag found matching #{opts.inspect} in:\n#{@session.response.body.inspect}"
        end
      end
      
      # Identical to #assert_tag, but asserts that a matching tag does _not_
      # exist. (See #assert_tag for a full discussion of the syntax.)
      def assert_no_tag(*opts)
        clean_backtrace do
          opts = opts.size > 1 ? opts.last.merge({ :tag => opts.first.to_s }) : opts.first
          tag = find_tag(opts)
          assert !tag, "expected no tag, but found tag matching #{opts.inspect} in:\n#{@session.response.body.inspect}"
        end
      end

      # test 2 html strings to be equivalent, i.e. identical up to reordering of attributes
      def assert_dom_equal(expected, actual, message="")
        clean_backtrace do
          expected_dom = HTML::Document.new(expected).root
          actual_dom = HTML::Document.new(actual).root
          full_message = build_message(message, "<?> expected to be == to\n<?>.", expected_dom.to_s, actual_dom.to_s)
          assert_block(full_message) { expected_dom == actual_dom }
        end
      end
      
      # negated form of +assert_dom_equivalent+
      def assert_dom_not_equal(expected, actual, message="")
        clean_backtrace do
          expected_dom = HTML::Document.new(expected).root
          actual_dom = HTML::Document.new(actual).root
          full_message = build_message(message, "<?> expected to be != to\n<?>.", expected_dom.to_s, actual_dom.to_s)
          assert_block(full_message) { expected_dom != actual_dom }
        end
      end

      # ensures that the passed record is valid by active record standards. returns the error messages if not
      def assert_valid(record)
        clean_backtrace do
          assert record.valid?, record.errors.full_messages.join("\n")
        end
      end    

      def clean_backtrace(&block)
        yield
      rescue Exception => e         
        path = File.expand_path(__FILE__)
        raise Exception, e.message, e.backtrace.reject { |line| File.expand_path(line) =~ /#{path}/ }
      end

end