const { load } = require('cheerio')
const Message = require('.')

module.exports = class XmlMessage extends Message {
  /**
   * Parses the XML message.
   * @public
   */
  parse () {
    this._raw = this.value
    this.value = load(this.value, {
      xml: true
    })
    this._parsedXml = this.value.xml()

    this.type = this.value('body').attr('action')
  }

  /**
   * Converts the value back to a message string. An unchanged message goes
   * out exactly as it came in: re-serializing turns the client's
   * single-quoted attributes into double-quoted ones, which servers that
   * match the client's own format (Burrow) don't read.
   * @returns {string}
   * @public
   */
  toMessage () {
    const xml = this.value.xml()
    return xml === this._parsedXml ? this._raw : xml
  }
}
