
class DifferController < ApplicationController

  def diff
    @lights = avatar.lights.map(&:to_json)
    diff = differ.diff(avatar, was_tag, now_tag)
    view = git_diff_view(diff)
    render json: {
                         id: kata.id,
                     avatar: avatar.name,
                     wasTag: was_tag,
                     nowTag: now_tag,
                     lights: @lights,
	                    diffs: view,
                 prevAvatar: ring_prev(active_avatar_names, avatar.name),
                 nextAvatar: ring_next(active_avatar_names, avatar.name),
	      idsAndSectionCounts: prune(view),
          currentFilenameId: pick_file_id(view, current_filename),
	  }
  end

  private

  include GitDiffView
  include RingPicker
  include ReviewFilePicker

  def was_tag
    tag(:was_tag)
  end

  def now_tag
    tag(:now_tag)
  end

  def tag(n)
    raw = params[n].to_i
    raw != -1 ? raw : @lights.length
  end

  def current_filename
    params[:current_filename]
  end

  def active_avatar_names
    @active_avatar_names ||= avatars.active.map(&:name).sort
  end

  def prune(array)
    array.map { |hash| { :id => hash[:id], :section_count => hash[:section_count] } }
  end

end
