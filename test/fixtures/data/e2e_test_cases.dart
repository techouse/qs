const List<({Object? data, String encoded})> e2eTestCases = [
  // empty dict
  (data: <String, dynamic>{}, encoded: ''),

  // simple dict with single key-value pair
  (data: <String, dynamic>{'a': 'b'}, encoded: 'a=b'),

  // simple dict with multiple key-value pairs 1
  (data: <String, dynamic>{'a': 'b', 'c': 'd'}, encoded: 'a=b&c=d'),

  // simple dict with multiple key-value pairs 2
  (
    data: <String, dynamic>{'a': 'b', 'c': 'd', 'e': 'f'},
    encoded: 'a=b&c=d&e=f'
  ),

  // dict with list
  (
    data: <String, dynamic>{
      'a': 'b',
      'c': 'd',
      'e': <Object?>['f', 'g', 'h'],
    },
    encoded: 'a=b&c=d&e[0]=f&e[1]=g&e[2]=h'
  ),

  // dict with list and nested dict
  (
    data: <String, dynamic>{
      'a': 'b',
      'c': 'd',
      'e': <Object?>['f', 'g', 'h'],
      'i': <String, dynamic>{'j': 'k', 'l': 'm'},
    },
    encoded: 'a=b&c=d&e[0]=f&e[1]=g&e[2]=h&i[j]=k&i[l]=m'
  ),

  // simple 1-level nested dict
  (
    data: <String, dynamic>{
      'a': <String, dynamic>{'b': 'c'},
    },
    encoded: 'a[b]=c'
  ),

  // two-level nesting
  (
    data: <String, dynamic>{
      'a': <String, dynamic>{
        'b': <String, dynamic>{'c': 'd'},
      },
    },
    encoded: 'a[b][c]=d'
  ),

  // list of dicts
  (
    data: <String, dynamic>{
      'a': <Map<String, dynamic>>[
        {'b': 'c'},
        {'d': 'e'},
      ],
    },
    encoded: 'a[0][b]=c&a[1][d]=e'
  ),

  // single-item list
  (
    data: <String, dynamic>{
      'a': <Object?>['f']
    },
    encoded: 'a[0]=f'
  ),

  // nested list inside a dict inside a list
  (
    data: <String, dynamic>{
      'a': <Object?>[
        <String, dynamic>{
          'b': <Object?>['c']
        }
      ],
    },
    encoded: 'a[0][b][0]=c'
  ),

  // empty-string value
  (data: <String, dynamic>{'a': ''}, encoded: 'a='),

  // list containing an empty string
  (
    data: <String, dynamic>{
      'a': <Object?>['', 'b']
    },
    encoded: 'a[0]=&a[1]=b'
  ),

  // unicode-only key and value
  (data: <String, dynamic>{'キー': '値'}, encoded: 'キー=値'),

  // emoji (multi-byte unicode) in key and value
  (data: <String, dynamic>{'🙂': '😊'}, encoded: '🙂=😊'),

  // complex dict with special characters
  (
    data: <String, dynamic>{
      'filters': <String, dynamic>{
        r'$or': <Object?>[
          <String, dynamic>{
            'date': <String, dynamic>{r'$eq': '2020-01-01'}
          },
          <String, dynamic>{
            'date': <String, dynamic>{r'$eq': '2020-01-02'}
          },
        ],
        'author': <String, dynamic>{
          'name': <String, dynamic>{r'$eq': 'John Doe'},
        },
      },
    },
    encoded:
        r'filters[$or][0][date][$eq]=2020-01-01&filters[$or][1][date][$eq]=2020-01-02&filters[author][name][$eq]=John Doe'
  ),

  // dart_api_query/comments_embed_response
  (
    data: <String, dynamic>{
      'commentsEmbedResponse': <Map<String, dynamic>>[
        {
          'id': '1',
          'post_id': '1',
          'someId': 'ma018-9ha12',
          'text': 'Hello',
          'replies': <Map<String, dynamic>>[
            {
              'id': '3',
              'comment_id': '1',
              'someId': 'ma020-9ha15',
              'text': 'Hello'
            },
          ],
        },
        {
          'id': '2',
          'post_id': '1',
          'someId': 'mw012-7ha19',
          'text': 'How are you?',
          'replies': <Map<String, dynamic>>[
            {
              'id': '4',
              'comment_id': '2',
              'someId': 'mw023-9ha18',
              'text': 'Hello'
            },
            {
              'id': '5',
              'comment_id': '2',
              'someId': 'mw035-0ha22',
              'text': 'Hello'
            },
          ],
        },
      ],
    },
    encoded:
        'commentsEmbedResponse[0][id]=1&commentsEmbedResponse[0][post_id]=1&commentsEmbedResponse[0][someId]=ma018-9ha12&commentsEmbedResponse[0][text]=Hello&commentsEmbedResponse[0][replies][0][id]=3&commentsEmbedResponse[0][replies][0][comment_id]=1&commentsEmbedResponse[0][replies][0][someId]=ma020-9ha15&commentsEmbedResponse[0][replies][0][text]=Hello&commentsEmbedResponse[1][id]=2&commentsEmbedResponse[1][post_id]=1&commentsEmbedResponse[1][someId]=mw012-7ha19&commentsEmbedResponse[1][text]=How are you?&commentsEmbedResponse[1][replies][0][id]=4&commentsEmbedResponse[1][replies][0][comment_id]=2&commentsEmbedResponse[1][replies][0][someId]=mw023-9ha18&commentsEmbedResponse[1][replies][0][text]=Hello&commentsEmbedResponse[1][replies][1][id]=5&commentsEmbedResponse[1][replies][1][comment_id]=2&commentsEmbedResponse[1][replies][1][someId]=mw035-0ha22&commentsEmbedResponse[1][replies][1][text]=Hello'
  ),

  // dart_api_query/comments_response
  (
    data: <String, dynamic>{
      'commentsResponse': <Map<String, dynamic>>[
        {
          'id': '1',
          'post_id': '1',
          'someId': 'ma018-9ha12',
          'text': 'Hello',
          'replies': <Map<String, dynamic>>[
            {
              'id': '3',
              'comment_id': '1',
              'someId': 'ma020-9ha15',
              'text': 'Hello'
            },
          ],
        },
        {
          'id': '2',
          'post_id': '1',
          'someId': 'mw012-7ha19',
          'text': 'How are you?',
          'replies': <Map<String, dynamic>>[
            {
              'id': '4',
              'comment_id': '2',
              'someId': 'mw023-9ha18',
              'text': 'Hello'
            },
            {
              'id': '5',
              'comment_id': '2',
              'someId': 'mw035-0ha22',
              'text': 'Hello'
            },
          ],
        },
      ],
    },
    encoded:
        'commentsResponse[0][id]=1&commentsResponse[0][post_id]=1&commentsResponse[0][someId]=ma018-9ha12&commentsResponse[0][text]=Hello&commentsResponse[0][replies][0][id]=3&commentsResponse[0][replies][0][comment_id]=1&commentsResponse[0][replies][0][someId]=ma020-9ha15&commentsResponse[0][replies][0][text]=Hello&commentsResponse[1][id]=2&commentsResponse[1][post_id]=1&commentsResponse[1][someId]=mw012-7ha19&commentsResponse[1][text]=How are you?&commentsResponse[1][replies][0][id]=4&commentsResponse[1][replies][0][comment_id]=2&commentsResponse[1][replies][0][someId]=mw023-9ha18&commentsResponse[1][replies][0][text]=Hello&commentsResponse[1][replies][1][id]=5&commentsResponse[1][replies][1][comment_id]=2&commentsResponse[1][replies][1][someId]=mw035-0ha22&commentsResponse[1][replies][1][text]=Hello'
  ),

  // dart_api_query/post_embed_response
  (
    data: <String, dynamic>{
      'data': <String, dynamic>{
        'id': '1',
        'someId': 'af621-4aa41',
        'text': 'Lorem Ipsum Dolor',
        'user': <String, dynamic>{
          'firstname': 'John',
          'lastname': 'Doe',
          'age': '25',
        },
        'relationships': <String, dynamic>{
          'tags': <String, dynamic>{
            'data': <Object?>[
              {'name': 'super'},
              {'name': 'awesome'},
            ],
          },
        },
      },
    },
    encoded:
        'data[id]=1&data[someId]=af621-4aa41&data[text]=Lorem Ipsum Dolor&data[user][firstname]=John&data[user][lastname]=Doe&data[user][age]=25&data[relationships][tags][data][0][name]=super&data[relationships][tags][data][1][name]=awesome'
  ),

  // dart_api_query/post_response
  (
    data: <String, dynamic>{
      'id': '1',
      'someId': 'af621-4aa41',
      'text': 'Lorem Ipsum Dolor',
      'user': <String, dynamic>{
        'firstname': 'John',
        'lastname': 'Doe',
        'age': '25',
      },
      'relationships': <String, dynamic>{
        'tags': <Object?>[
          {'name': 'super'},
          {'name': 'awesome'},
        ],
      },
    },
    encoded:
        'id=1&someId=af621-4aa41&text=Lorem Ipsum Dolor&user[firstname]=John&user[lastname]=Doe&user[age]=25&relationships[tags][0][name]=super&relationships[tags][1][name]=awesome'
  ),

  // dart_api_query/posts_response
  (
    data: <String, dynamic>{
      'postsResponse': <Map<String, dynamic>>[
        {
          'id': '1',
          'someId': 'du761-8bc98',
          'text': 'Lorem Ipsum Dolor',
          'user': <String, dynamic>{
            'firstname': 'John',
            'lastname': 'Doe',
            'age': '25',
          },
          'relationships': <String, dynamic>{
            'tags': <Object?>[
              {'name': 'super'},
              {'name': 'awesome'},
            ],
          },
        },
        {
          'id': '1',
          'someId': 'pa813-7jx02',
          'text': 'Lorem Ipsum Dolor',
          'user': <String, dynamic>{
            'firstname': 'Mary',
            'lastname': 'Doe',
            'age': '25',
          },
          'relationships': <String, dynamic>{
            'tags': <Object?>[
              {'name': 'super'},
              {'name': 'awesome'},
            ],
          },
        },
      ],
    },
    encoded:
        'postsResponse[0][id]=1&postsResponse[0][someId]=du761-8bc98&postsResponse[0][text]=Lorem Ipsum Dolor&postsResponse[0][user][firstname]=John&postsResponse[0][user][lastname]=Doe&postsResponse[0][user][age]=25&postsResponse[0][relationships][tags][0][name]=super&postsResponse[0][relationships][tags][1][name]=awesome&postsResponse[1][id]=1&postsResponse[1][someId]=pa813-7jx02&postsResponse[1][text]=Lorem Ipsum Dolor&postsResponse[1][user][firstname]=Mary&postsResponse[1][user][lastname]=Doe&postsResponse[1][user][age]=25&postsResponse[1][relationships][tags][0][name]=super&postsResponse[1][relationships][tags][1][name]=awesome'
  ),

  // dart_api_query/posts_response_paginate
  (
    data: <String, dynamic>{
      'posts': <Map<String, dynamic>>[
        {
          'id': '1',
          'someId': 'du761-8bc98',
          'text': 'Lorem Ipsum Dolor',
          'user': <String, dynamic>{
            'firstname': 'John',
            'lastname': 'Doe',
            'age': '25',
          },
          'relationships': <String, dynamic>{
            'tags': <Object?>[
              {'name': 'super'},
              {'name': 'awesome'},
            ],
          },
        },
        {
          'id': '1',
          'someId': 'pa813-7jx02',
          'text': 'Lorem Ipsum Dolor',
          'user': <String, dynamic>{
            'firstname': 'Mary',
            'lastname': 'Doe',
            'age': '25',
          },
          'relationships': <String, dynamic>{
            'tags': <Object?>[
              {'name': 'super'},
              {'name': 'awesome'},
            ],
          },
        },
      ],
      'total': '2',
    },
    encoded:
        'posts[0][id]=1&posts[0][someId]=du761-8bc98&posts[0][text]=Lorem Ipsum Dolor&posts[0][user][firstname]=John&posts[0][user][lastname]=Doe&posts[0][user][age]=25&posts[0][relationships][tags][0][name]=super&posts[0][relationships][tags][1][name]=awesome&posts[1][id]=1&posts[1][someId]=pa813-7jx02&posts[1][text]=Lorem Ipsum Dolor&posts[1][user][firstname]=Mary&posts[1][user][lastname]=Doe&posts[1][user][age]=25&posts[1][relationships][tags][0][name]=super&posts[1][relationships][tags][1][name]=awesome&total=2'
  ),
];
