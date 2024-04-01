const List<({Object? data, String encoded})> e2eTestCases = [
  (
    data: {},
    encoded: '',
  ),
  (
    data: {'a': 'b'},
    encoded: 'a=b',
  ),
  (
    data: {'a': 'b', 'c': 'd'},
    encoded: 'a=b&c=d',
  ),
  (
    data: {'a': 'b', 'c': 'd', 'e': 'f'},
    encoded: 'a=b&c=d&e=f',
  ),
  (
    data: {
      'a': 'b',
      'c': 'd',
      'e': ['f', 'g', 'h']
    },
    encoded: 'a=b&c=d&e[0]=f&e[1]=g&e[2]=h',
  ),
  (
    data: {
      'a': 'b',
      'c': 'd',
      'e': ['f', 'g', 'h'],
      'i': {'j': 'k', 'l': 'm'}
    },
    encoded: 'a=b&c=d&e[0]=f&e[1]=g&e[2]=h&i[j]=k&i[l]=m',
  ),
  (
    data: {
      'filters': {
        r'$or': [
          {
            'date': {
              r'$eq': '2020-01-01',
            }
          },
          {
            'date': {
              r'$eq': '2020-01-02',
            }
          }
        ],
        'author': {
          'name': {
            r'$eq': 'John Doe',
          },
        }
      }
    },
    encoded:
        r'filters[$or][0][date][$eq]=2020-01-01&filters[$or][1][date][$eq]=2020-01-02&filters[author][name][$eq]=John Doe',
  ),
];
