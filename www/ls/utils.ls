ig.utils = utils = {}


utils.offset = (element, side) ->
  top = 0
  left = 0
  do
    top += element.offsetTop
    left += element.offsetLeft
  while element = element.offsetParent
  {top, left}


utils.deminifyData = (minified) ->
  out = for row in minified.data
    row_out = {}
    for column, index in minified.columns
      row_out[column] = row[index]
    for column, indices of minified.indices
      row_out[column] = indices[row_out[column]]
    row_out
  out


utils.formatNumber = (input, decimalPoints = 0) ->
  input = parseFloat input
  if decimalPoints
    wholePart = Math.floor input
    decimalPart = Math.abs input % 1
    wholePart = insertThousandSeparator wholePart
    decimalPart = Math.round decimalPart * Math.pow 10, decimalPoints
    decimalPart = decimalPart.toString()
    while decimalPart.length < decimalPoints
      decimalPart = "0" + decimalPart
    "#{wholePart},#{decimalPart}"
  else
    wholePart = Math.round input
    insertThousandSeparator wholePart


insertThousandSeparator = (input, separator = ' ') ->
    price = Math.round(input).toString()
    out = []
    len = price.length
    for i in [0 til len]
      out.unshift price[len - i - 1]
      isLast = i is len - 1
      isThirdNumeral = 2 is i % 3
      if isThirdNumeral and not isLast
        out.unshift separator
    out.join ''

utils.backbutton = (parent) ->
  parent.append \a
    ..attr \class \backbutton
    ..html '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" width="76" height="76" viewBox="0 0 76.00 76.00" enable-background="new 0 0 76.00 76.00" xml:space="preserve"><path fill="#000000" fill-opacity="1" stroke-width="0.2" stroke-linejoin="round" d="M 57,42L 57,34L 32.25,34L 42.25,24L 31.75,24L 17.75,38L 31.75,52L 42.25,52L 32.25,42L 57,42 Z "/></svg>'
