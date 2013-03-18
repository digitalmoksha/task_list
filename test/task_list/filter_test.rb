# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)
require 'task_list/filter'

class TaskList::FilterTest < Test::Unit::TestCase
  def setup
    @pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      TaskList::Filter
    ], {}, {}

    @context = {}
    @item_selector = "input.task-list-item-checkbox[type=checkbox]"
  end

  def test_filters_items_in_a_list
    text = <<-md
- [ ] incomplete
- [x] complete
    md
    assert_equal 2, filter(text)[:output].css(@item_selector).size
  end

  def test_filters_items_with_HTML_contents
    text = <<-md
- [ ] incomplete **with bold** text
- [x] complete __with italic__ text
    md
    assert_equal 2, filter(text)[:output].css(@item_selector).size
  end

  def test_filters_items_in_a_list_wrapped_in_paras
    # See issue #7951 for details.
    text = <<-md
- [ ] one
- [ ] this one will be wrapped in a para

- [ ] this one too, wtf
    md
    assert_equal 3, filter(text)[:output].css(@item_selector).size
  end

  def test_populates_result_with_task_list_items
    text = <<-md
- [ ] incomplete
- [x] complete
    md

    result = filter(text)
    assert !result[:task_list_items].empty?
    incomplete, complete = result[:task_list_items]

    assert incomplete
    assert_equal 1, incomplete.index
    assert !incomplete.complete?

    assert complete
    assert_equal 2, complete.index
    assert complete.complete?
  end

  def test_skips_lists_in_code_blocks
    code = <<-md
```
- [ ] incomplete
- [x] complete
```
    md

    assert filter(code)[:output].css(@item_selector).empty?,
      "should not have any task list items"
  end

  def test_handles_encoding_correctly
    unicode = "中文"
    text = <<-md
- [ ] #{unicode}
    md
    assert item = filter(text)[:output].css('.task-list-item').pop
    assert_equal unicode, item.text.strip
  end

  protected

  def filter(input, context = @context, result = nil)
    result ||= {}
    @pipeline.call(input, context, result)
  end
end