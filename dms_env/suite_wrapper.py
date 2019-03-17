#!/usr/bin/env python

import time
import numpy as np
from dm_control import suite
from catalyst.contrib.registry import Registry


@Registry.environment
class SuiteWrapper:
    def __init__(
        self,
        domain=None,
        task=None,
        domain_task=None,
        visualize=False,
        frame_skip=1,
        reward_scale=1,
        step_delay=0.1
    ):
        if domain_task is not None:
            domain, task = domain_task.rsplit("-", 1)
        assert domain, task
        self.env = suite.load(domain_name=domain, task_name=task)

        self.visualize = visualize
        self.frame_skip = frame_skip
        self.reward_scale = reward_scale
        self.step_delay = step_delay

        self.observation_shape = self.get_spec_shape(
            self.env.observation_spec())
        self.action_shape = self.get_spec_shape(
            self.env.action_spec())

        self.time_step = 0
        self.total_reward = 0

    @staticmethod
    def get_spec_shape(spec):
        if isinstance(spec, dict):
            spec_values = spec.values()
            return (
                sum(
                    x.shape[0] if len(x.shape) > 0 else 1
                    for x in spec_values),
            )
        else:
            return spec.shape

    @staticmethod
    def _to_list_of_arrays(iterable):
        return [
            np.array([x])
            if not isinstance(x, np.ndarray)
            else x
            for x in iterable
        ]

    @staticmethod
    def get_observation(suite_step):
        return np.concatenate(
            SuiteWrapper._to_list_of_arrays(suite_step.observation.values())
        )

    def reset(self):
        self.time_step = 0
        self.total_reward = 0
        suite_step = self.env.reset()
        return self.get_observation(suite_step)

    def step(self, action):
        time.sleep(self.step_delay)
        reward = 0
        for i in range(self.frame_skip):
            suite_step = self.env.step(action)
            observation = self.get_observation(suite_step)
            r = suite_step.reward
            done = suite_step.step_type.last()
            if self.visualize:
                self.env.render()
            reward += r
            if done:
                break
        self.total_reward += reward
        self.time_step += 1
        info = {"reward_origin": reward}
        reward *= self.reward_scale
        return observation, reward, done, info
