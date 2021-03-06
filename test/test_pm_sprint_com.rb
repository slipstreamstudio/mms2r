require File.join(File.dirname(__FILE__), "test_helper")

class TestPmSprintCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def mock_sprint_image(message_id)
    uri = URI.parse('http://pictures.sprintpcs.com//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90')
    res = mock()
    body = mock()
    res.expects(:content_type).at_least_once.returns('image/jpeg')
    res.expects(:body).once.returns(body)
    res.expects(:code).never
    Net::HTTP.expects(:get_response).once.returns res
  end

  def mock_sprint_purged_image(message_id)
    uri = URI.parse('http://pictures.sprintpcs.com//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90')
    res = mock()
    body = mock()
    res.expects(:content_type).once.returns('text/html')
    res.expects(:code).once.returns('500')
    res.expects(:body).never
    Net::HTTP.expects(:get_response).once.returns res
  end

  def test_mms_should_have_text
    mail = mail('sprint-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068765309", mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    file = mms.media['text/plain'].first
    assert_equal true, File.exist?(file)
    assert_match(/\.txt$/, File.basename(file))
    assert_equal "Tea Pot", IO.read(file)
    mms.purge
  end

  def test_mms_should_have_a_phone_number
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    mms.purge
  end

  def test_should_have_simple_video
    mail = mail('sprint-video-01.mail')

    uri = URI.parse(
     'http://pictures.sprintpcs.com//mmps/RECIPIENT/000_259e41e851be9b1d_1/2?inviteToken=lEvrJnPVY5UfOYmahQcx&amp;iconifyVideo=true&amp;wm=1&amp;limitsize=125,125&amp;outquality=90&amp;squareoutput=255,255,255&amp;ext=.jpg&amp;iconifyVideo=true&amp;wm=1')
    res = mock()
    body = mock()
    res.expects(:content_type).at_least_once.returns('video/quicktime')
    res.expects(:body).once.returns(body)
    res.expects(:code).never
    Net::HTTP.expects(:get_response).once.returns res

    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['video/quicktime']
    assert_equal 1, mms.media['video/quicktime'].size
    assert_equal "000_259e41e851be9b1d_1-0.mov", File.basename(mms.media['video/quicktime'][0])

    mms.purge
  end

  def test_should_have_simple_image
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/001_2066c7013e7ca833_1-0.jpg$/, mms.media['image/jpeg'][0])

    mms.purge
  end

  def test_collect_image_using_block
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal 1, mms.media.size
    file_array = nil
    mms.process do |k, v|
      file_array = v if (k == 'image/jpeg')
      assert_equal 1, file_array.size
      file = file_array.first
      assert_not_nil file = file_array.first
      assert_equal "001_2066c7013e7ca833_1-0.jpg", File.basename(file)
    end
    mms.purge
  end

  def test_process_internals_should_only_be_executed_once
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal 1, mms.media.size

    # second time through shouldn't go into the was_processed block
    mms.mail.expects(:parts).never

    mms.process{|k, v| }

    mms.purge
  end

  def test_should_have_two_images
    mail = mail('sprint-two-images-01.mail')

    uri1 = URI.parse('http://pictures.sprintpcs.com/mmps/RECIPIENT/001_104058d23d79fb6a_1/2?wm=1&ext=.jpg&iconifyVideo=true&inviteToken=5E1rJSPk5hYDkUnY7op0&outquality=90')
    res1 = mock()
    body1 = mock()
    res1.expects(:content_type).at_least_once.returns('image/jpeg')
    res1.expects(:body).once.returns(body1)
    res1.expects(:code).never
    Net::HTTP.expects(:get_response).returns res1

    uri2 = URI.parse('http://pictures.sprintpcs.com/mmps/RECIPIENT/001_104058d23d79fb6a_1/3?wm=1&ext=.jpg&iconifyVideo=true&inviteToken=5E1rJSPk5hYDkUnY7op0&outquality=90')

    res2 = mock()
    body2 = mock()
    res2.expects(:content_type).at_least_once.returns('image/jpeg')
    res2.expects(:body).once.returns(body2)
    res2.expects(:code).never
    Net::HTTP.expects(:get_response).returns res2
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_equal 2, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'][0]
    assert_not_nil mms.media['image/jpeg'][1]
    assert_match(/001_104058d23d79fb6a_1-0.jpg$/, mms.media['image/jpeg'][0])
    assert_match(/001_104058d23d79fb6a_1-1.jpg$/, mms.media['image/jpeg'][1])

    mms.purge
  end

  def test_image_should_be_missing
    # this test is questionable
    mail = mail('sprint-broken-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_image_should_be_purged_from_content_server
    mail = mail('sprint-image-01.mail')
    mock_sprint_purged_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_body_should_return_empty_when_there_is_no_user_text
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal "", mms.body
  end

  def test_sprint_write_file
    require 'tempfile'
    mail = mock(:message_id => 'a')
    mail.expects(:from).at_least_once.returns(['joe@pm.sprint.com'])
    mail.expects(:return_path).at_least_once.returns('joe@pm.sprint.com')
    s = MMS2R::Media::Sprint.new(mail, :process => :lazy)
    type = 'text/plain'
    content = 'foo'
    file = Tempfile.new('sprint')
    file.close

    type, file = s.send(:sprint_write_file, type, content, file.path)
    assert_equal 'text/plain', type
    assert_equal content, IO.read(file)
  end

  def test_subject
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal "", mms.subject
  end

end
