function readTranslatedValue(jsonObject, key)
{
    var translatedValue = jsonObject[key + '[' + Qt.locale().name + ']']
    if (translatedValue != undefined) return translatedValue
    return jsonObject[key]
}
