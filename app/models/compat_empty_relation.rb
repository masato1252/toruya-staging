# frozen_string_literal: true

class CompatEmptyRelation
  def exists?(*)
    false
  end

  def count
    0
  end

  def order(*)
    self
  end

  def where(*)
    self
  end

  def find(*)
    raise ActiveRecord::RecordNotFound
  end

  def find_by(*)
    nil
  end

  def active
    self
  end

  def setup_pending
    self
  end

  def first
    nil
  end

  def to_a
    []
  end

  def map(*)
    []
  end

  def each
    [].each
  end
end
