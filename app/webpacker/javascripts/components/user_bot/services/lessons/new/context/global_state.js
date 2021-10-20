import React, { createContext, useReducer, useMemo, useContext } from "react";
import _ from "lodash";
import Routes from 'js-routes.js'

import combineReducer from "context/combine_reducer";
import LessonCreationReducer from "./lesson_creation_reducer";
import { CommonServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  lesson_creation_states: LessonCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        lesson_creation_states: {
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  const lessonData = () => {
    return {
      ...state.lesson_creation_states
    }
  }

  const createLesson = async () => {
    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_service_chapter_lessons_path(props.lesson.online_service_id, props.lesson.chapter_id),
      data: lessonData()
    })

    if (response?.data?.status == "successful") {
      window.location = response.data.redirect_to
    } else {
      alert(error?.message || response.data?.error_message)
    }
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.lesson_creation_states,
      dispatch,
      createLesson
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
