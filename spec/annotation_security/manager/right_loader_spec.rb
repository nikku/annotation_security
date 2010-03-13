require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::RightLoader do

  it "should allow right definitions by hash" do
    AnnotationSecurity::RightLoader.define_rights({
      :right_loader => {
        :right1 => 'if logged_in',
        :right2 => 'if may_right1',
      }})
    (defined? RightLoaderPolicy).should_not be_nil
    RightLoaderPolicy.has_rule?(:right1).should be_true
    RightLoaderPolicy.has_rule?(:right2).should be_true
  end

end

