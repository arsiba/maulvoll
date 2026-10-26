class DomainError < StandardError
  attr_reader :status

  def initialize(message, status = 422)
    @status = status
    super(message)
  end
end
