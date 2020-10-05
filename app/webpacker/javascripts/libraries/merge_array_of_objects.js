import _ from "lodash";

// object1 = { a: [1, 2], b: [2, 3, 4], c: [2] }
// object2 = { a: [2, 3], b: [1, 3, 4] }
// mergeArrayOfObjects(object1, object2)
// {
//   a: [1, 2, 3]
//   b: [2, 3, 4, 1]
//   c: [2]
// }

const mergeArrayOfObjects = (object1, object2) => {
  const keys = _.uniq(Object.keys(object1), Object.keys(object2))
  const mergedObject = {}

  keys.forEach((key) => {
    mergedObject[key] = _.uniq([...(object1[key] || []), ...(object2[key] || [])])
  })

  return mergedObject
}

export default mergeArrayOfObjects;
