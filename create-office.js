// wd create-entity create-office.js "Minister for X"
module.exports = (label) => {
  return {
    type: 'item',
    labels: {
      en: label,
    },
    descriptions: {
      en: 'position in the Cabinet of Ukraine',
    },
    claims: {
      P31:   { value: 'Q294414' }, // instance of: public office
      P279:  { value: 'Q83307'  }, // subclas of: minister
      P17:   { value: 'Q212'    }, // country: Ukraine
      P1001: { value: 'Q212'    }, // jurisdiction: Ukraine
      P361: {
        value: 'Q613729',          // part of: Council of Ministers of Ukraine
        references: {
          P854: 'https://www.kmu.gov.ua/en/team'
        },
      }
    }
  }
}
