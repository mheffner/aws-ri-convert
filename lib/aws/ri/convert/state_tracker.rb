
class StateTracker
  def initialize(checkpointer, name)
    @checkpointer = checkpointer
    @name = name
    @state = @checkpointer.load(name) || {}
  end

  def empty?
    @state.empty?
  end

  def [](key)
    @state[key]
  end

  def []=(key, value)
    @state[key] = value
    save
  end

  def set(hash)
    @state = hash
    save
  end

  private

  def save
    @checkpointer.save(@name, @state)
  end
end
