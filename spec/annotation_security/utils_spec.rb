require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AnnotationSecurity::Utils do

  it 'should remove prefixes of the method body' do
    %w{may_rule is_rule can_rule has_rule}.each do |method|
      AnnotationSecurity::Utils.method_body(method).should eql('rule')
    end
  end

  it 'should remove suffixes of the method body' do
    %w{rule_for rule_of rule_in rule_to rule?}.each do |method|
      AnnotationSecurity::Utils.method_body(method).should eql('rule')
    end
  end

  it 'should return nil if the method body is clean' do
    AnnotationSecurity::Utils.method_body('rule').should be_nil
  end

  it 'should ignore prefixes and suffixes without underscore in method body' do
    %w{mayrule isrule rulefor ruleof canrulein hasruleto}.each do |method|
      AnnotationSecurity::Utils.method_body(method).should eql(nil)
    end
  end

  it 'should remove only prefix or suffix from the method body at a time' do
    AnnotationSecurity::Utils.method_body('may_is_rule').should eql('is_rule')
    AnnotationSecurity::Utils.method_body('rule_of_for').should eql('rule_of')
    AnnotationSecurity::Utils.method_body('can_has_rule_to?').should eql('has_rule_to')
  end

  it 'should parse descriptions without bindings correctly' do
    ['show a resource', 'show with some text ignored a resource',
     'show pluralized resources', '(ignoring comments) show a resource',
     'show a resource (with comment at the end)'].each do |s|
      AnnotationSecurity::Utils.parse_description(s).
        should == {:action => :show, :resource => :resource}
    end
  end

  it 'should detect bindings of a description' do
    {
      'show the resource in @res' => 
        {:action => :show,:resource => :resource, :source => '@res'},
      'show the resource from :id' =>
        {:action => :show,:resource => :resource, :source => :id},
    }.each_pair do |key, value|
      AnnotationSecurity::Utils.parse_description(key,true).should == value
    end
  end

  it 'should raise an error if an unexpected binding is detected in a description' do
    lambda {
      AnnotationSecurity::Utils.parse_description('show the resource :id')
    }.should raise_error(StandardError)
  end

  it 'should parse policy arguments like specified in SecurityContext.allowed?' do
    obj = Object.new
    def obj.__is_resource?; true; end
    def obj.resource_type; :o_resource; end
    {
      [:show, :resource, obj] => [:show, :resource, obj],
      [:show, obj] => [:show, :o_resource, obj],
      ['show resource', obj] => [:show, :resource, obj],
      [:show, :resource] => [:show, :resource],
      [:administrate] => [:administrate, :all_resources]
    }.each_pair do |key, value|
      AnnotationSecurity::Utils.parse_policy_arguments(key).should == value
    end
  end

end