$(->
  remoteSelector   = "form[data-remote], a[data-remote]"
  formSelector     = "form"
  linkSelector     = "a"
  lockName         = "atomic-lock"

  canMakeAtomicRequest = (element) ->
    if element.data(lockName) then false else setAtomicLock(element)

  setAtomicLock = (element, value) ->
    value ?= true
    element.data(lockName, value)
    value

  notRemoteRequest = (element) ->
    element.not(remoteSelector)

  $(document).on("ajax:beforeSend", remoteSelector, ->
    element = $(this)
    canMakeAtomicRequest(element)
  )

  $(document).on("ajax:complete", remoteSelector, ->
    element = $(this)
    setAtomicLock(element, false)
  )

  $(document).on("submit", formSelector, ->
    form = $(this)
    canMakeAtomicRequest(form) if notRemoteRequest(form)
  )

  $(document).on("click", linkSelector, (event) ->
    link = $(this)
    if notRemoteRequest(link) && !canMakeAtomicRequest(link)
      event.preventDefault()
  )
)
