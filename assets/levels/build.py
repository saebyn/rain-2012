#!/usr/bin/env python2.7

import yaml
import json
import collections


# From http://stackoverflow.com/questions/3232943/update-value-of-a-nested-dictionary-of-varying-depth/3233356#3233356
def deep_update(d, u):
    for k, v in u.iteritems():
        if isinstance(v, collections.Mapping):
            r = deep_update(d.get(k, {}), v)
            d[k] = r
        else:
            d[k] = u[k]
    
    return d


def apply_includes(tree):
    """
    Find all included files and insert their contents into the tree.
    """
    includes = tree.get('includes', [])
    if 'includes' in tree:
        del tree['includes']

    for fn in includes:
        with open(fn) as fp:
            deep_update(tree, apply_includes(yaml.load(fp)))

    return tree


def extract_parts(tree):
    """
    Remove the settings and entities from the tree.

    >>> extract_parts({'settings': 123, 'entities': 'abc'})
    (123, 'abc')
    """
    return tree['settings'], tree['entities']


def apply_inheritance(tree):
    """
    Find all entities with the 'extends' attribute and apply parent attributes
    to children when not overridden until all entities are touched.

    >>> apply_inheritance({
    ...   'a': {'type': 'test', 'details': {'x': 1}},
    ...   'b': {'extends': 'a'},
    ... }) == {'a': {'type': 'test', 'details': {'x': 1}}, 'b': {'type': 'test', 'details': {'x': 1}}}
    True
    >>> apply_inheritance({
    ...   'a': {'type': 'test'},
    ...   'b': {'extends': 'a'},
    ... }) == {'a': {'type': 'test'}, 'b': {'type': 'test'}}
    True
    >>> apply_inheritance({
    ...   'a': {'type': 'test'},
    ...   'b': {'extends': 'a'},
    ...   'c': {'extends': 'b', 'type': 'final'},
    ...   'd': {'extends': 'c'},
    ... }) == {'a': {'type': 'test'}, 'b': {'type': 'test'}, 'c': {'type': 'final'}, 'd': {'type': 'final'}}
    True
    """
    def recurse(entity):
        if 'extends' in entity:
            if type(entity['extends']) == type(''):
                parents = [entity['extends']]
            else:
                parents = entity['extends']

            props = {}
            for parent in parents:
                # gather inherited properties
                inherited_properties = recurse(tree[parent])
                if 'abstract' in inherited_properties:
                    del inherited_properties['abstract']

                deep_update(props, inherited_properties)

            # override inherited properties with the entity's props
            deep_update(props, entity)

            # copy back the entity's props
            entity.update(props)

            # done with parents
            del entity['extends']

        # allow children to inherit this entities properties
        return entity.copy()

    try:
        for entity_name in tree:
            recurse(tree[entity_name])
    except KeyError, e:
        print 'Error: Entity not found: ' + e

    return tree


def remove_abstract(tree):
    """
    Remove all entities that are marked as abstract.

    >>> remove_abstract({'a': {'abstract': True}})
    {}
    >>> remove_abstract({'a': {'abstract': False}})
    {'a': {}}
    >>> remove_abstract({'a': {'type': 'test'}})
    {'a': {'type': 'test'}}
    >>> remove_abstract({'a': {'abstract': True},
    ...                  'b': {'abstract': False},
    ...                  'c': {'type': 'test'}}) == {'b': {}, 'c': {'type': 'test'}}
    True
    """
    removals = []
    for entity in tree:
        if 'abstract' in tree[entity]:
            if tree[entity]['abstract']:
                removals.append(entity)

            del tree[entity]['abstract']

    for removal in removals:
        del tree[removal]

    return tree


def extract_details(tree):
    """
    Extract the entity properties from the details block into the main dict.

    >>> extract_details({'a': {'details': {'x': 1}}})
    {'a': {'x': 1}}
    """
    for entity in tree:
        if 'details' in tree[entity]:
            details = tree[entity]['details']
            tree[entity].update(details)
            del tree[entity]['details']

    return tree


def split_entities(tree):
    """
    Split the entities in the parse tree into separate subdictionaries by type.

    >>> split_entities({'a': {'type': 'portal'},
    ...                 'b': {'type': 'solid'}})
    {'portals': {'a': {}}, 'solids': {'b': {}}}
    >>> split_entities({'a': {'type': 'portal', 'attribute': True},
    ...                 'b': {'type': 'solid', 'attribute': False}})
    {'portals': {'a': {'attribute': True}}, 'solids': {'b': {'attribute': False}}}
    """
    mappings = {'portal': 'portals', 'solid': 'solids', 'npc': 'npcs',
                'background': 'backgrounds'}
    new_tree = {}
    for entity in tree:
        if mappings[tree[entity]['type']] not in new_tree:
            new_tree[mappings[tree[entity]['type']]] = {}

        type_tree = new_tree[mappings[tree[entity]['type']]]
        type_tree[entity] = tree[entity]
        del type_tree[entity]['type']

    return new_tree


def format_npc_behaviors(tree):
    for npc in tree['npcs'].values():
        npc['behavior'] = (npc['behavior']['initial'],
                           npc['behavior']['table'],
                           npc['behavior']['transitions'])

    return tree


def apply_settings(tree, settings):
    """
    Inserts level settings into their proper place.

    >>> apply_settings({}, {'size': [10, 10], 'playerStart': [1, 1]}) ==  {'size': [10, 10], 'playerStart': [1, 1]}
    True
    >>> apply_settings({'solids': {}}, {'size': [10, 10], 'playerStart': [1, 1]}) ==  {'solids': {}, 'size': [10, 10], 'playerStart': [1, 1]}
    True
    """
    copy = tree.copy()
    copy.update(settings)
    return copy


def convert(filename):
    level = apply_includes({'includes': [filename]})
    settings, level = extract_parts(level)
    level = apply_inheritance(level)
    level = remove_abstract(level)
    level = extract_details(level)
    level = split_entities(level)
    level = format_npc_behaviors(level)
    level = apply_settings(level, settings)
    print json.dumps(level)

if __name__ == '__main__':
    import sys
    if len(sys.argv) == 2:
        convert(sys.argv[1])
    else:
        import doctest
        doctest.testmod()
